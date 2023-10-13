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
FileAllocationTable::FileAllocationTable(unsigned int _nrbanks) :
    nrbanks(_nrbanks) {
    this->contents = std::vector<char>(0x10000 * this->nrbanks, 0x00);
    this->cache_status = std::vector<uint8_t>(0x10000 * 8 / 0x100, CACHE_UNKNOWN);
}

/**
 * @brief Check whether this ROM chip is correctly formatted
 * @return whether rom chip is correctly formatted
 */
bool FileAllocationTable::check_fat() {
    // loop over all programs and capture starting blocks
    emit(this->message("Parsing banks..."));
    this->progblocks.clear();
    this->files.clear();
    for(unsigned int bank=0; bank<this->nrbanks; bank++) {
        QByteArray data = this->read_sector(bank * 0x10);

        // check whether data is correctly set
        for(unsigned int i=0; i<60; i++) {
            // check bank
            if((uint8_t)data[0x100 + i * 0x40] != bank) {
                qDebug() << tr("Bank %1 does not have bank digit set to %2 (%3)")
                            .arg(bank).arg((unsigned int)bank).arg((unsigned int)data[0x100 + i * 0x40]);
                return false;
            }

            // check lower bytes start address
            if((uint8_t)data[0x100 + i * 0x40 + 1] != 0x00) {
                qDebug() << tr("Bank %1 does not have lower byte set to %2")
                            .arg(bank).arg((unsigned int)0x00);
                return false;
            }

            // check upper bytes start address
            if((uint8_t)data[0x100 + i * 0x40 + 2] != (i * 4 + 0x10)) {
                qDebug() << tr("Bank %1 does not have upper byte set to %2 (%3)")
                            .arg(bank)
                            .arg(i * 4 + 0x10, 2, 16, QLatin1Char('0'))
                            .arg((uint8_t)data[0x100 + i * 0x40 + 2], 2, 16, QLatin1Char('0'));
                return false;
            }
        }
    }

    return true;
}

/**
 * @brief Format the chip
 */
void FileAllocationTable::format_chip() {
    for(unsigned int bank=0; bank<this->nrbanks; bank++) {
        this->serial_interface->open_port();

        // erase all banks on sector
        for(unsigned int i=0; i<0x10; i++) {
            this->serial_interface->erase_sector(bank * 0x100 + i * 0x10);
        }

        QByteArray data(0x1000, 0xFF);
        for(unsigned int i=0; i<60; i++) {
            data[0x100 + i * 0x40] = bank;
            data[0x100 + i * 0x40 + 1] = 0x00;
            data[0x100 + i * 0x40 + 2] = i * 4 + 0x10;
        }

        this->serial_interface->burn_sector(bank * 0x10, data);
        this->serial_interface->close_port();
    }

    // clean cache
    memset(this->cache_status.data(), 0x00, this->cache_status.size());
    emit(signal_sync_status_changed(this->cache_status));
}

/**
 * @brief Read file metadata from chip
 */
void FileAllocationTable::read_files() {
    // loop over all programs and capture starting blocks
    emit(this->message("Parsing banks..."));
    this->progblocks.clear();
    this->files.clear();
    for(unsigned int bank=0; bank<this->nrbanks; bank++) {
        emit(this->read_operation(bank,this->nrbanks));
        QByteArray data = this->read_block(bank * 0x100);
        unsigned int ptr = 0x0000;
        while(ptr < 0x100) {
            uint8_t blockid = data[ptr++];
            if(blockid == 0xFF) {
                break;
            } else {
                this->progblocks.emplace_back(bank, blockid);
                qInfo() << "Found program: BANK " << (unsigned int)bank << " BLOCK " << (unsigned int)blockid;
            }
        }
    }

    // loop over all starting blocks and read file descriptors
    int ctr = 0;
    emit(this->message("Parsing file metadata..."));
    for(const auto& loc : this->progblocks) {
        emit(this->read_operation(ctr++, this->progblocks.size()));
        unsigned int addr = loc.first * 0x10000 + 0x100 + loc.second * 0x40;    // start address of metadata
        unsigned int offset = addr % 0x100;                                     // determine block offset
        uint8_t sector_id = addr >> 12 & 0xFF;                                  // determine sector

        QByteArray sectordata = this->read_sector(sector_id);                   // read complete sector
        QByteArray block = sectordata.mid(addr & 0x0F00);                       // grab block from sector
        QByteArray metadata = block.mid(offset, 0x40);                          // grab metada from block

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

    // build name and extension
    QString filename = (base.toLower().trimmed() + "_" + QString::fromUtf8(file.extension,3).toLower()) + ".cas";

    // replace spaces by
    filename = filename.remove(QRegExp("[^a-zA-Z\\d\\s")).replace(" ", "_");

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

    uint16_t filesize = (uint8_t)header[0x02] + (uint8_t)header[0x03] * 256; // big endian
    qInfo() << tr("Header claims file size is: %1 bytes").arg(filesize);

    // determine number of blocks based on data size as we cannot a priori
    // trust the header block for that; check therefore whether the data size
    // is divisable by 0x400
    if(data.size() % 0x400 != 0) {
        throw std::runtime_error("Data size should be divisable by 0x400.");
    }
    uint8_t nrblocks = data.size() / 0x400;

    // assert whether filesize as indicated in header is sensible
    bool reformat = false;
    if(!(filesize <= nrblocks * 0x400 && filesize > (nrblocks-1) * 0x400)) {
        qWarning() << "Invalid header size encountered, reformatting metadata";
        filesize = nrblocks * 0x400;
        reformat = true;
    }

    qInfo() << "Starting looking for free blocks";
    emit(read_operation(0, nrblocks));
    auto newbankblock = this->find_next_free_block();

    // loop over program blocks
    for(uint8_t i=0; i<nrblocks; i++) {
        uint8_t newbank = newbankblock.first;
        uint8_t newblock = newbankblock.second;

        if(i == 0) { // write start position in preample
            qInfo() << "Placing startblock in preample";
            char *ptr = &this->contents[newbank * 0x10000];
            while((uint8_t)*ptr != 0xFF) {
                ptr++;
            }
            *ptr = newblock;
            this->update_cache_status(newbank * 0x10000 / 0x100, CACHE_WRITE_NONERASE);
        }

        qDebug() << "Placing contents in: " << newbank << " / " << newblock;

        // copy raw file header
        unsigned int headeroffset = newbank * 0x10000 + 0x100 + 0x40 * newblock;
        qInfo() << tr("Copying header to 0x%1").arg(headeroffset, 6, 16, QLatin1Char('0'));
        memcpy(&this->contents[headeroffset + 0x20], header.data(), 0x20);
        this->contents[headeroffset + 0x08] = 0x00;         // designating block as used
        this->contents[headeroffset + 0x09] = i;            // set current block
        this->contents[headeroffset + 0x0A] = nrblocks;     // set total number of blocks

        // overwriting header format if it is invalid
        if(reformat) {
            this->contents[headeroffset + 0x22] = filesize & 0xFF;
            this->contents[headeroffset + 0x23] = filesize >> 8;
            this->contents[headeroffset + 0x24] = filesize & 0xFF;
            this->contents[headeroffset + 0x25] = filesize >> 8;
            this->contents[headeroffset + 0x3F] = nrblocks - i;
        }

        // marking blocks as unsynced
        this->update_cache_status(headeroffset / 0x100, CACHE_WRITE_NONERASE);

        // copy data
        unsigned int dataoffset = newbank * 0x10000 + 0x400 * (newblock + 4);
        qInfo() << tr("Copying data to 0x%1").arg(dataoffset, 6, 16, QLatin1Char('0'));
        uint8_t sector_id = dataoffset / 0x1000;
        this->read_sector(sector_id); // ensure required sector is loaded
        QByteArray blockdata = data.mid(i*0x400,0x400);
        memcpy(&this->contents[dataoffset], blockdata.data(), 0x400);

        uint16_t checksum = this->crc16_xmodem(blockdata, 0x400);
        this->contents[headeroffset + 0x06] = (uint8_t)(checksum & 0xFF);   // set checksum
        this->contents[headeroffset + 0x07] = (uint8_t)(checksum >> 8);

        // marking blocks as unsynced
        for(unsigned int j=0; j<4; j++) {
            this->update_cache_status(dataoffset / 0x100 + j, CACHE_WRITE_NONERASE);
        }

        // set next bank and block if not the last block
        newbankblock = this->find_next_free_block();
        if(i != nrblocks - 1) {
            this->contents[headeroffset + 0x03] = newbankblock.first;
            this->contents[headeroffset + 0x04] = newbankblock.second;
        }
    }

    emit(signal_sync_needed());
}

/**
 * @brief Remove a file from the ROM chip
 * @param file_id
 */
void FileAllocationTable::delete_file(unsigned int file_id) {
    this->build_linked_list(file_id);       // build linked list of file on rom chip
    const auto& linked_list = this->files[file_id].blocks;
    QString filename = QString::fromUtf8(this->files[file_id].filename, 16);

    qInfo() << "Removing file: " << filename;

    // clean up the metadata segment on the corresponding bank
    this->read_sector(linked_list[0].first * 0x10); // ensure sector is read before overwriting any data
    char* ptr = &this->contents.data()[linked_list[0].first * 0x10000];
    std::vector<uint8_t> newlist;
    while(*ptr != (char)0xFF) {
        if(*ptr != linked_list[0].second) {
            newlist.push_back(*ptr);
        }
        ptr++;
    }

    // overwrite last values
    newlist.push_back(0xFF);
    newlist.push_back(0xFF);

    // copy newlist to contents section
    memcpy(&this->contents[0x10000 * linked_list[0].first], newlist.data(), newlist.size());

    // and invalidate the memory with an erase instruction
    this->update_cache_status(linked_list[0].first * 0x100, CACHE_WRITE_ERASE);

    // loop over all blocks and wipe these as well
    for(const auto& bankblock : linked_list) {
        const uint8_t bank = bankblock.first;
        const uint8_t block = bankblock.second;

        // wipe metadata
        unsigned int headeroffset = 0x10000 * bank + 0x100 + block * 0x40;
        static const std::vector<char> wipe(0x400, (char)0xFF);
        memcpy(&this->contents[headeroffset], wipe.data(), 0x40);

        this->contents[headeroffset + 0x00] = bank;
        this->contents[headeroffset + 0x01] = 0x00;
        this->contents[headeroffset + 0x02] = block * 4 + 0x10;

        // wipe regular data
        unsigned int dataoffset = 0x10000 * bank + 0x1000 + block * 0x400;
        this->read_sector(dataoffset / 0x1000); // ensure data is read before overwriting
        memcpy(&this->contents[dataoffset], wipe.data(), 0x400);
        for(unsigned int i=0; i<4; i++) {
            this->update_cache_status(dataoffset / 0x100 + i, CACHE_WRITE_ERASE);
        }
    }

    emit(signal_sync_needed());
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

    if(this->cache_status[address] == CACHE_SYNCED) {
        QByteArray data(&this->contents[address * 0x100], 0x100);
        return data;
    } else {
        this->serial_interface->open_port();
        QByteArray data = this->serial_interface->read_block(address);
        this->serial_interface->close_port();
        memcpy((void*)&this->contents[address * 0x100], data.data(), 0x100);
        this->update_cache_status(address, CACHE_SYNCED);
        return data;
    }
}

/**
 * @brief Read a sector (0x1000 bytes) from the chip, use caching
 * @param block address (0x1000 segment)
 * @return datablock
 */
QByteArray FileAllocationTable::read_sector(uint8_t sector_id) {
    for(unsigned int i=0; i<BLOCKS_PER_SECTOR; i++) {
        if(this->cache_status[sector_id * BLOCKS_PER_SECTOR + i] == CACHE_UNKNOWN) {
            this->serial_interface->open_port();
            QByteArray data = this->serial_interface->read_sector(sector_id);
            this->serial_interface->close_port();
            memcpy((void*)&this->contents[sector_id *SECTOR_SIZE], data.data(), SECTOR_SIZE);
            for(unsigned int j=0; j<BLOCKS_PER_SECTOR; j++) {
                this->update_cache_status(sector_id * BLOCKS_PER_SECTOR + j, CACHE_SYNCED);
            }
            break;
        }
    }

    return QByteArray(&this->contents[sector_id * SECTOR_SIZE], SECTOR_SIZE);
}

/**
 * @brief Read a bank of 0x4000 bytes
 * @param bank_id
 * @return datablock
 */
QByteArray FileAllocationTable::read_bank(uint8_t bank_id) {
    for(unsigned int i=0; i<BLOCKS_PER_BANK; i++) {
        if(this->cache_status[bank_id * BLOCKS_PER_BANK + i] == CACHE_UNKNOWN) {
            this->serial_interface->open_port();
            QByteArray data = this->serial_interface->read_bank(bank_id);
            this->serial_interface->close_port();
            memcpy((void*)&this->contents[bank_id * BANK_SIZE], data.data(), BANK_SIZE);
            for(unsigned int j=0; j<BLOCKS_PER_BANK; j++) {
                this->update_cache_status(bank_id * BLOCKS_PER_BANK + j, CACHE_SYNCED);
            }
            break;
        }
    }

    return QByteArray(&this->contents[bank_id * BANK_SIZE], BANK_SIZE);

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

    if(this->cache_status[address] == CACHE_SYNCED) {
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
            this->update_cache_status(bank_address + i, CACHE_SYNCED);
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

/**
 * @brief Generate CRC16-XMODEM checksum for data
 * @param data
 * @param length
 * @return
 */
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
    for(uint8_t bank=0; bank<this->nrbanks; bank++) {
        QByteArray data = this->read_sector(bank * 0x10);
        for(uint8_t block=0; block<60; block++) {
            if((uint8_t)data.data()[0x100 + block*0x40+0x08] == 0xFF) {
                qInfo() << tr("Finding new block at bank %1, block %2").arg(bank).arg(block);
                return std::make_pair(bank, block);
            }
        }
    }

    throw std::runtime_error("Cannot find a new bank / block");
}

/**
 * @brief Update cache status
 * @param block_id
 * @param cache_status
 */
void FileAllocationTable::update_cache_status(unsigned int block_id, uint8_t cache_status) {
    this->cache_status[block_id] = cache_status;
    emit(signal_sync_status_changed(this->cache_status));
}
