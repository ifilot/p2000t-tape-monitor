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

/**
 * @brief Class containing file metadata and data
 */
class File {
public:
    char filename[16];
    char extension[3];
    uint16_t size;
    uint8_t startblock;
    uint8_t startbank;
    std::vector<std::pair<uint8_t, uint8_t>> blocks;
    QByteArray data;
};

/**
 * @brief Class to interface with the P2000T File Allocation Table
 */
class FileAllocationTable : public QObject {
    Q_OBJECT
private:
    std::shared_ptr<SerialInterface> serial_interface;
    std::vector<std::pair<unsigned int, unsigned int>> progblocks;
    std::vector<File> files;

    // enable caching
    std::vector<char> contents;
    std::vector<uint8_t> cache_status;

public:
    /**
     * @brief Default constructor
     */
    FileAllocationTable();

    /**
     * @brief Connect Serial interface object to class
     * @param _serial_interface
     */
    void set_serial_interface(const std::shared_ptr<SerialInterface>& _serial_interface) {
        this->serial_interface = _serial_interface;
    }

    /**
     * @brief Read file metadata from chip
     */
    void read_files();

    /**
     * @brief Get a list of filenames
     * @return list of filenames
     */
    QStringList get_files() const;

    /**
     * @brief Get total number of files
     * @return number of files
     */
    size_t get_num_files() const {
        return this->files.size();
    }

    /**
     * @brief Get a single file
     * @param file index
     * @return file (meta-)data
     */
    const File& get_file(unsigned int id);

signals:
    /**
     * @brief signal when a read operation is conducted
     * @param sector_id
     */
    void read_operation(int item, int total);

    /**
     * @brief Parse message
     * @param str
     */
    void message(QString str);

private:
    /**
     * @brief Read a block (0x100 bytes) from the chip, use caching
     * @param address
     * @return datablock
     */
    QByteArray read_block(unsigned int address);

    /**
     * @brief Extract linked list of file
     * @param vector of bank/block pairs
     */
    void build_linked_list(unsigned int id);

    /**
     * @brief Attach file data to file object
     * @param file id
     */
    void attach_filedata(unsigned int id);
};

#endif // FILEALLOCATIONTABLE_H
