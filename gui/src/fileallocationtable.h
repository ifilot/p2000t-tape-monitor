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

#ifndef FILEALLOCATIONTABLE_H
#define FILEALLOCATIONTABLE_H

#include <QByteArray>
#include <memory>
#include "serial_interface.h"

class File {
public:
    char filename[16];
    char extension[3];
    uint16_t size;
    uint8_t startblock;
    uint8_t startbank;
    std::vector<std::pair<unsigned int, unsigned int>> blocks;
    QByteArray data;
};

class FileAllocationTable {
private:
    std::shared_ptr<SerialInterface> serial_interface;
    std::vector<std::pair<unsigned int, unsigned int>> progblocks;
    std::vector<File> files;

    // enable caching
    std::vector<char> contents;
    std::vector<uint8_t> cache_status;

public:
    FileAllocationTable();

    void set_serial_interface(const std::shared_ptr<SerialInterface>& _serial_interface) {
        this->serial_interface = _serial_interface;
    }

    void read_files();

    QStringList get_files() const;

    size_t get_num_files() const {
        return this->files.size();
    }

    const File& get_file(unsigned int id);

private:
    QByteArray read_block(unsigned int address);

    void build_linked_list(unsigned int id);

    void attach_filedata(unsigned int id);
};

#endif // FILEALLOCATIONTABLE_H
