/****************************************************************************
 *                                                                          *
 *   P2000T-FAT-READER                                                      *
 *   Copyright (C) 2023 Ivo Filot <ivo@ivofilot.nl>                         *
 *                                                                          *
 *   This program is free software: you can redistribute it and/or modify   *
 *   it under the terms of the GNU Lesser General Public License as         *
 *   published by the Free Software Foundation, either version 3 of the     *
 *   License, or (at your option) any later version.                        *
 *                                                                          *
 *   This program is distributed in the hope that it will be useful,        *
 *   but WITHOUT ANY WARRANTY; without even the implied warranty of         *
 *   MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the          *
 *   GNU General Public License for more details.                           *
 *                                                                          *
 *   You should have received a copy of the GNU General Public license      *
 *   along with this program.  If not, see <https://www.gnu.org/licenses/>. *
 *                                                                          *
 ****************************************************************************/

#include "fileallocationtable.h"

/**
 * @brief Default constructor
 */
FileAllocationTable::FileAllocationTable() {
    this->contents = std::vector<char>(0x10000 * 8, 0x00);
    this->cache_status = std::vector<uint8_t>(0x10000 * 8 / 0x100, 0x00);
}

/**
 * @brief Read file metadata from chip
 */
void FileAllocationTable::read_files() {
    // loop over all programs and capture starting blocks
    emit(this->message("Parsing banks..."));
    for(unsigned int bank=0; bank<8; bank++) {
        emit(this->read_operation(bank,8));
        QByteArray data = this->read_block(bank * 0x100);
        unsigned int ptr = 0x0000;
        while(ptr < 0x100) {
            uint8_t blockid = data[ptr++];
            if(blockid == 0xFF) {
                break;
            } else {
                this->progblocks.emplace_back(bank, blockid);
                qDebug() << "Found program: " << (unsigned int)bank << "," << (unsigned int)blockid;
            }
        }
    }

    // loop over all starting blocks and read file descriptors
    int ctr = 0;
    emit(this->message("Parsing file metadata..."));
    for(const auto& loc : this->progblocks) {
        emit(this->read_operation(ctr++, this->progblocks.size()));
        unsigned int addr = loc.first * 0x10000 + 0x100 + loc.second * 0x40;
        unsigned int saddr = addr / 0x100;
        unsigned int offset = addr % 0x100;

        QByteArray meta = this->read_block(saddr);
        QByteArray metadata = meta.mid(offset, 0x40);

        File file;
        memcpy(file.filename, &metadata.data()[0x26], 8);
        memcpy(&file.filename[8], &metadata.data()[0x37], 8);
        memcpy(file.extension, &metadata.data()[0x2E], 3);
        file.startbank = loc.first;
        file.startblock = loc.second;
        file.size = *((uint16_t*)&metadata.data()[0x24]);
        this->files.push_back(file);
    }
    emit(this->message("Done loading file metadata."));
}

/**
 * @brief Get a list of filenames
 * @return list of filenames
 */
QStringList FileAllocationTable::get_files() const {
    QStringList list;
    for(const auto& file : this->files) {
        list.append(QString::fromUtf8(file.filename, 16));
    }

    return list;
}

/**
 * @brief Get a single file
 * @param file index
 * @return file (meta-)data
 */
const File& FileAllocationTable::get_file(unsigned int id) {
    emit(this->message("Transferring file from chip..."));
    this->build_linked_list(id);
    this->attach_filedata(id);
    emit(this->message(tr("Succesfully loaded %1").arg(QString::fromUtf8(this->files[id].filename, 16))));

    // perform checksums
    qDebug() << "Performing checksum check";
    for(unsigned int i=0; i<this->files[id].blocks.size(); i++) {
        QByteArray block = this->files[id].data.mid(i*0x400, 0x400);
        uint16_t crc16 = this->crc16_xmodem(block, i+1 != this->files[id].blocks.size() ? 0x400 : this->files[id].size - i * 0x400);
        qDebug() << tr("0x%1 vs 0x%2").arg(crc16,4,16,QLatin1Char('0')).arg(this->files[id].checksums[i],4,16,QLatin1Char('0'));
    }

    return this->files[id];
}

/**
 * @brief Read a block (0x100 bytes) from the chip, use caching
 * @param address
 * @return datablock
 */
QByteArray FileAllocationTable::read_block(unsigned int address) {
    if(address > this->cache_status.size()) {
        std::runtime_error("Attempting to access cache_status element out of bounds.");
    }

    if(this->cache_status[address] == 0x01) {
        QByteArray data(&this->contents[address * 0x100], 0x100);
        return data;
    } else {
        this->serial_interface->open_port();
        QByteArray data = this->serial_interface->read_block(address);
        this->serial_interface->close_port();
        memcpy((void*)&this->contents[address * 0x100], data.data(), 0x100);
        this->cache_status[address] = 0x01;
        return data;
    }
}

/**
 * @brief Extract linked list of file
 * @param vector of bank/block pairs
 */
void FileAllocationTable::build_linked_list(unsigned int id) {
    auto& file = this->files[id];
    if(file.blocks.size() != 0) {
        return;
    }

    uint8_t bank = file.startbank;
    uint8_t block = file.startblock;

    while(bank != 0xFF) {
        // insert into list
        file.blocks.emplace_back(bank, block);

        // set address locations for metadata of current block
        unsigned int addr = bank * 0x10000 + 0x100 + block * 0x40;
        unsigned int saddr = addr / 0x100;
        unsigned int offset = addr % 0x100;

        // read metadata of current block
        QByteArray meta = this->read_block(saddr);
        QByteArray metadata = meta.mid(offset, 0x40);

        // retrieve data of new block
        bank = metadata[0x03];  // next bank
        block = metadata[0x04]; // next block

        // retrieve and store checksum of current block
        uint16_t checksum = *((uint16_t*)&metadata.data()[0x06]);
        file.checksums.push_back(checksum);
    }
}

/**
 * @brief Attach file data to file object
 * @param file id
 */
void FileAllocationTable::attach_filedata(unsigned int id) {
    auto& file = this->files[id];
    if(file.blocks.size() == 0) {
        this->build_linked_list(id);
    }

    if(file.size == file.data.size()) {
        return;
    }

    int ctr = 0;
    for(const auto& p : file.blocks) {
        emit(this->read_operation(ctr++, file.blocks.size()));
        unsigned int addr = p.first * 0x10000 + 0x1000 + p.second * 0x400;
        unsigned int saddr = addr / 0x100;

        for(unsigned int i=0; i<4; i++) {
            QByteArray data = this->read_block(saddr + i);
            file.data.append(data);
        }
    }

    file.data.resize(file.size);
}

uint16_t FileAllocationTable::crc16_xmodem(const QByteArray& data, uint16_t length) {
    uint32_t crc = 0;
    static const uint16_t poly = 0x1021;

    for(uint16_t i=0; i<length; i++) {
      crc = crc ^ (data[i] << 8);
      for (uint8_t j=0; j<8; j++) {
        crc = crc << 1;
        if (crc & 0x10000) {
            crc = (crc ^ poly) & 0xFFFF;
        }
      }
    }

    return (uint16_t)crc;
}
