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

FileAllocationTable::FileAllocationTable() {
    this->contents = std::vector<char>(0x10000 * 8, 0x00);
    this->cache_status = std::vector<uint8_t>(0x10000 * 8 / 0x100, 0x00);
}

void FileAllocationTable::read_files() {
    // loop over all programs and capture starting blocks
    for(unsigned int bank=0; bank<8; bank++) {
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
    for(const auto& loc : this->progblocks) {
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
        file.size = metadata.data()[0x22] + metadata.data()[0x23] * 256; // big endian
        this->files.push_back(file);
    }
}

QStringList FileAllocationTable::get_files() const {
    QStringList list;
    for(const auto& file : this->files) {
        list.append(QString::fromUtf8(file.filename, 16));
    }

    return list;
}

QByteArray FileAllocationTable::read_block(unsigned int address) {
    if(address > this->cache_status.size()) {
        std::runtime_error("Attempting to access cache_status element out of bounds.");
    }

    if(this->cache_status[address] == 0x01) {
        qDebug() << "Cache hit: copying";
        QByteArray data(&this->contents[address * 0x100], 0x100);
        return data;
    } else {
        this->serial_interface->open_port();
        QByteArray data = this->serial_interface->read_block(address);
        this->serial_interface->close_port();
        qDebug() << "Inserting into cache:";
        memcpy((void*)&this->contents[address * 0x100], data.data(), 0x100);
        this->cache_status[address] = 0x01;
        return data;
    }
}

const File& FileAllocationTable::get_file(unsigned int id) {
    this->build_linked_list(id);
    this->attach_filedata(id);
    return this->files[id];
}

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

        unsigned int addr = bank * 0x10000 + 0x100 + block * 0x40;
        unsigned int saddr = addr / 0x100;
        unsigned int offset = addr % 0x100;

        QByteArray meta = this->read_block(saddr);
        QByteArray metadata = meta.mid(offset, 0x40);

        bank = metadata[0x03];  // next bank
        block = metadata[0x04]; // next block
    }
}

void FileAllocationTable::attach_filedata(unsigned int id) {
    auto& file = this->files[id];
    if(file.blocks.size() == 0) {
        this->build_linked_list(id);
    }

    if(file.size == file.data.size()) {
        return;
    }

    for(const auto& p : file.blocks) {
        unsigned int addr = p.first * 0x10000 + 0x1000 + p.second * 0x400;
        unsigned int saddr = addr / 0x100;

        qDebug() << "Reading: " << p.first << "." << p.second;

        for(unsigned int i=0; i<4; i++) {
            QByteArray data = this->read_block(saddr + i);
            file.data.append(data);
        }
    }

    file.data.resize(file.size);
}
