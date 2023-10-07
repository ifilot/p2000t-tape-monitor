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
    this->progblocks.clear();
    this->files.clear();
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
 * @brief Get a list of filenames
 * @return list of filenames
 */
QStringList FileAllocationTable::get_files_listing() const {
    QStringList list;
    unsigned int ctr=0;
    for(const auto& file : this->files) {
        ctr++;
        list.append(
            QString("%1 %2 | %3 | %4 %5")
                .arg(ctr,3,10,QLatin1Char('0'))
                .arg(QString::fromUtf8(file.filename, 16), 16, QLatin1Char(' '))
                .arg(file.size,5)
                .arg(file.startbank,2)
                .arg(file.startblock,2)
        );
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

    return this->files[id];
}

/**
 * @brief Get a single file
 * @param file index
 * @return file (meta-)data
 */
const File& FileAllocationTable::get_file_metadata(unsigned int id) {
    return this->files[id];
}

/**
 * @brief Create a CAS file from a file
 * @param id
 * @return
 */
QByteArray FileAllocationTable::create_cas_file(unsigned int id) {
    qDebug() << "Building CAS file";
    const auto& file = this->get_file(id);

    QByteArray data = QByteArray(file.blocks.size() * 0x500, 0x00);

    for(unsigned int i=0; i<file.blocks.size(); i++) {
        unsigned int addr = file.blocks[i].first * 0x10000 + 0x100 + file.blocks[i].second * 0x40;
        unsigned int saddr = addr / 0x100;
        unsigned int offset = addr % 0x100;

        QByteArray meta = this->read_block(saddr);
        QByteArray metadata = meta.mid(offset, 0x40);

        qDebug() << "Copying metadata for block " << i;
        memcpy(&(data.data()[i*0x500 + 0x30]), &(metadata.data()[0x20]), 0x20);
        qDebug() << "Copying data for block " << i;
        memcpy(&(data.data()[i*0x500 + 0x100]), &(file.data.data()[i*0x400]), 0x400);
    }

    return data;
}

/**
 * @brief Get checksums
 * @return
 */
std::vector<std::pair<uint16_t, uint16_t>> FileAllocationTable::get_checksum_pairs(unsigned int id) {
    const auto& file = this->get_file(id);
    std::vector<std::pair<uint16_t, uint16_t>> checksums;

    for(unsigned int i=0; i<file.checksums.size(); i++) {
        checksums.emplace_back(file.metachecksums[i], file.checksums[i]);
    }

    return checksums;
}

/**
 * @brief Construct a filename for a given file
 * @param id
 * @return
 */
QString FileAllocationTable::build_filename(unsigned int id) {
    const auto& file = this->get_file(id);
    QString base = QString::fromUtf8(file.filename,16).simplified();
    QString filename = base.toLower() + "_" + QString::fromUtf8(file.extension,3).toLower() + ".cas";

    return filename;
}

/**
 * @brief Get number of occupied blocks (0x400 byte sections)
 * @return number of occupied blocks
 */
unsigned int FileAllocationTable::get_number_occupied_blocks() const {
    unsigned int numblocks = 0;
    for(const auto& file : this->files) {
        unsigned int sz = file.size;
        numblocks += sz / 0x400;
        if(sz % 0x400 != 0) {
            numblocks++;
        }
    }

    return numblocks;
}

/**
 * @brief Add file to FAT
 * @param header
 * @param data
 */
void FileAllocationTable::add_file(const QByteArray& header, const QByteArray& data) {
    qDebug() << "Adding file";

    char filename[16];
    memcpy(filename, header.data() + 0x06, 8);
    memcpy(&filename[8], header.data() + 0x17, 8);

    uint16_t filesize = (uint8_t)header[0x02] + (uint8_t)header[0x03] * 256;
    uint8_t nrblocks = (uint8_t)header[0x1F];

    qDebug() << "Starting looking for free blocks";
    emit(read_operation(0, nrblocks));
    auto newbankblock = this->find_next_free_block();

    for(uint8_t i=0; i<nrblocks; i++) {
        uint8_t newbank = newbankblock.first;
        uint8_t newblock = newbankblock.second;

        if(i == 0) { // write start position in preample
            qDebug() << "Placing startblock in preample";
            char *ptr = &this->contents[newbank * 0x10000];
            while((uint8_t)*ptr != 0xFF) {
                ptr++;
            }
            *ptr = newblock;
            this->cache_status[newbank * 0x10000 / 0x100] = 0x02;
        }

        qDebug() << "Placing contents in: " << newbank << " / " << newblock;

        // copy raw file header
        unsigned int headeroffset = newbank * 0x10000 + 0x100 + 0x40 * newblock;
        qDebug() << tr("Copying header to 0x%1").arg(headeroffset, 6, 16, QLatin1Char('0'));
        memcpy(&this->contents[headeroffset + 0x20], header.data(), 0x20);
        this->contents[headeroffset + 0x08] = 0x00;         // designating block as used
        this->contents[headeroffset + 0x09] = i;            // set current block
        this->contents[headeroffset + 0x0A] = nrblocks;     // set total number of blocks

        // marking blocks as unsynced
        this->cache_status[headeroffset / 0x100] = 0x02;

        // copy data
        unsigned int dataoffset = newbank * 0x10000 + 0x400 * (newblock + 4);
        qDebug() << tr("Copying data to 0x%1").arg(dataoffset, 6, 16, QLatin1Char('0'));
        uint8_t bank_id = dataoffset / 0x4000;
        this->read_bank(bank_id); // ensure bank is loaded
        QByteArray blockdata = data.mid(i*0x400,0x400);
        memcpy(&this->contents[dataoffset], blockdata.data(), 0x400);

        uint16_t checksum = this->crc16_xmodem(blockdata, 0x400);
        this->contents[headeroffset + 0x06] = (uint8_t)(checksum & 0xFF);   // set checksum
        this->contents[headeroffset + 0x07] = (uint8_t)(checksum >> 8);

        // marking blocks as unsynced
        for(unsigned int j=0; j<4; j++) {
            this->cache_status[dataoffset / 0x100 + j] = 0x02;
        }

        // set next bank and block if not the last block
        newbankblock = this->find_next_free_block();
        if(i != nrblocks - 1) {
            this->contents[headeroffset + 0x03] = newbankblock.first;
            this->contents[headeroffset + 0x04] = newbankblock.second;
        }
    }
}

/**
 * @brief Read a block (0x100 bytes) from the chip, use caching
 * @param block address (0x100 segment)
 * @return datablock
 */
QByteArray FileAllocationTable::read_block(unsigned int address) {
    if(address > this->cache_status.size()) {
        std::runtime_error("Attempting to access cache_status element out of bounds.");
    }

    if(this->cache_status[address] >= 0x01) {
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
 * @brief Read a bank of 0x4000 bytes
 * @param bank_id
 * @return datablock
 */
QByteArray FileAllocationTable::read_bank(uint8_t bank_id) {
    for(unsigned int i=0; i<(0x4000 / 0x100); i++) {
        if(this->cache_status[bank_id * (0x4000 / 0x100) + i] < 0x01) {
            this->serial_interface->open_port();
            QByteArray data = this->serial_interface->read_bank(bank_id);
            this->serial_interface->close_port();
            memcpy((void*)&this->contents[bank_id * 0x4000], data.data(), 0x4000);
            for(unsigned int j=0; j<(0x4000 / 0x100); j++) {
                this->cache_status[bank_id * (0x4000 / 0x100) + j] = 0x01;
            }
            break;
        }
    }

    return QByteArray(&this->contents[bank_id * 0x4000], 0x4000);

}

/**
 * @brief Read the bank from a chip where the block resides in (more efficient caching)
 * @param block address (0x100 segment)
 * @return datablock
 */
QByteArray FileAllocationTable::read_block_cache_bank(unsigned int address) {
    if(address > this->cache_status.size()) {
        std::runtime_error("Attempting to access cache_status element out of bounds.");
    }

    if(this->cache_status[address] >= 0x01) {
        QByteArray data(&this->contents[address * 0x100], 0x100);
        return data;
    } else {
        // calculate bank address
        uint8_t bank_address = address / (0x4000 / 0x100);
        this->serial_interface->open_port();
        QByteArray data = this->serial_interface->read_bank(bank_address);
        this->serial_interface->close_port();

        memcpy((void*)&this->contents[bank_address * 0x4000], data.data(), 0x4000);

        for(unsigned int i=0; i<(0x4000 / 0x100); i++) {
            this->cache_status[bank_address + i] = 0x01;
        }
        return data;
    }
}

/**
 * @brief Extract linked list of file
 * @param vector of bank/block pairs
 */
void FileAllocationTable::build_linked_list(unsigned int id) {
    qDebug() << "Building linked list";
    auto& file = this->files[id];
    if(file.blocks.size() != 0) {
        return;
    }

    uint8_t bank = file.startbank;
    uint8_t block = file.startblock;
    unsigned int counter = 0;

    while(bank != 0xFF) {
        counter++;
        if(counter > 64 * 4) {
            throw std::runtime_error("Error occured while collecting linked list. Most likely a cyclic reference.");
        }

        qDebug() << "Collecting: " << bank << " / " << block;

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
        file.metachecksums.push_back(checksum);
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

    if(file.blocks.size() * 0x400 == file.data.size()) {
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

    for(unsigned int i=0; i<file.blocks.size(); i++) {
        QByteArray block = file.data.mid(i*0x400, 0x400);
        uint16_t crc16 = this->crc16_xmodem(block, 0x400);
        file.checksums.push_back(crc16);
        //qDebug() << tr("0x%1 vs 0x%2").arg(crc16,4,16,QLatin1Char('0')).arg(file.metachecksums[i],4,16,QLatin1Char('0'));
    }
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

/**
 * @brief find_next_free_block
 * @return
 */
std::pair<uint8_t, uint8_t> FileAllocationTable::find_next_free_block() {
    for(uint8_t bank=0; bank<8; bank++) {
        QByteArray data = this->read_bank(bank * 4);
        for(uint8_t block=0; block<60; block++) {
            if((uint8_t)data.data()[0x100 + block*0x40+0x08] == 0xFF) {
                return std::make_pair(bank, block);
            }
        }
    }

    return std::make_pair(0xFF, 0xFF);
}
