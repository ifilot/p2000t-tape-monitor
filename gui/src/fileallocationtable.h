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
    std::vector<uint16_t> metachecksums;    // checksums as supplied in metadata
    std::vector<uint16_t> checksums;        // checksums from data
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
     * @brief Get a list of filenames
     * @return list of filenames
     */
    QStringList get_files_listing() const;

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

    /**
     * @brief Get a single file
     * @param file index
     * @return file (meta-)data
     */
    const File& get_file_metadata(unsigned int id);

    /**
     * @brief Create a CAS file from a file
     * @param id
     * @return
     */
    QByteArray create_cas_file(unsigned int id);

    /**
     * @brief Get checksums
     * @return
     */
    std::vector<std::pair<uint16_t, uint16_t>> get_checksum_pairs(unsigned int id);

    /**
     * @brief Construct a filename for a given file
     * @param id
     * @return
     */
    QString build_filename(unsigned int id);

    /**
     * @brief Get number of occupied blocks (0x400 byte sections)
     * @return number of occupied blocks
     */
    unsigned int get_number_occupied_blocks() const;

    /**
     * @brief Add file to FAT
     * @param header
     * @param data
     */
    void add_file(const QByteArray& header, const QByteArray& data);

    inline const auto& get_contents() const {
        return this->contents;
    }

    inline const auto& get_cache_status() const {
        return this->cache_status;
    }

    inline void set_cache_status(const std::vector<uint8_t>& _cache_status) {
        this->cache_status = _cache_status;
    }

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
     * @brief Read a bank of 0x4000 bytes
     * @param bank_id
     * @return datablock
     */
    QByteArray read_bank(uint8_t bank_id);

    /**
     * @brief Read a block (0x100 bytes) from the chip, use caching
     * @param address
     * @return datablock
     */
    QByteArray read_block_cache_bank(unsigned int address);

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

    uint16_t crc16_xmodem(const QByteArray& data, uint16_t length);

    /**
     * @brief find_next_free_block
     * @return
     */
    std::pair<uint8_t, uint8_t> find_next_free_block();
};

#endif // FILEALLOCATIONTABLE_H
