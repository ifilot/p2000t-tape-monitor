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

#ifndef SYNCTHREAD_H
#define SYNCTHREAD_H

#include <QMessageBox>
#include <QIcon>
#include <vector>

#include "ioworker.h"

Q_DECLARE_METATYPE(std::vector<uint8_t>)

/**
 * @brief class for Flashing a cartridge
 *
 * Currently, only support for the AT28C256 is implemented.
 */
class SyncThread : public IOWorker {
    Q_OBJECT

private:
    // enable caching
    std::vector<char> contents;
    std::vector<uint8_t> cache_status;
    unsigned int nr_sectors = 0;

public:
    /**
     * @brief Default constructor
     */
    SyncThread() {}

    /**
     * @brief Constructor allocating SerialInterface
     * @param _serial_interface
     */
    SyncThread(const std::shared_ptr<SerialInterface>& _serial_interface) :
        IOWorker(_serial_interface) {}

    inline void set_contents(const std::vector<char>& _contents) {
        this->contents = _contents;
    }

    inline void set_cache_status(const std::vector<uint8_t>& _cache_status) {
        this->cache_status = _cache_status;
    }

    inline const auto& get_cache_status() const {
        return this->cache_status;
    }

    inline void set_sectors(unsigned int _nr_sectors) {
        this->nr_sectors = _nr_sectors;
    }

    /**
     * @brief run cart flash routine
     */
    void run() override;

    ~SyncThread();

private:

signals:
    /**
     * @brief signal when new page is written
     * @param block_id
     */
    void sync_item_done(int, int);

    /**
     * @brief signal when new page is written
     * @param block_id
     */
    void sync_complete();

    /**
     * @brief Signal when synchronization status has changed
     */
    void signal_sync_status_changed(const std::vector<uint8_t>);
};

#endif // SYNCTHREAD_H
