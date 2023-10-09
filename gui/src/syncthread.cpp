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

#include "syncthread.h"

/**
 * @brief run cart flash routine
 */
void SyncThread::run() {
    // maximum number of sectors
    static const unsigned int nrsects = 128;

    // determine number of sectors to write
    unsigned int nrsectowrite = 0;
    for(unsigned int i=0; i<nrsects; i++) { // loop over sectors
        for(unsigned int j=0; j<0x10; j++) {
            if(this->cache_status[i * 0x10 + j] == 0x02 ||
               this->cache_status[i * 0x10 + j] == 0x03) {
                nrsectowrite++;
                break;
            }
        }
    }

    unsigned int nrsects_written = 0;
    for(unsigned int i=0; i<nrsects; i++) { // loop over sectors
        for(unsigned int j=0; j<0x10; j++) {

            // if at least one sector page has a - to be written - flag, write
            // the whole sector
            if(this->cache_status[i * 0x10 + j] == 0x02 ||
               this->cache_status[i * 0x10 + j] == 0x03) {

                if(this->cache_status[i * 0x10 + j] == 0x03) {
                    qDebug() << "Erasing sector: " << i;
                    this->serial_interface->open_port();
                    this->serial_interface->erase_sector(i * 0x10); // !! this function takes a block_id as input !!
                    this->serial_interface->close_port();
                }

                qDebug() << "Writing sector: " << i;
                this->serial_interface->open_port();
                this->serial_interface->burn_sector(i, QByteArray(&this->contents[i * 0x1000], 0x1000));
                this->serial_interface->close_port();

                // emit status update
                emit(sync_item_done(++nrsects_written, nrsectowrite));

                // update cache status for the whole sector
                for(unsigned int k=0; k<0x10; k++) {
                    this->cache_status[i * 0x10 + k] = 0x01;
                    emit(signal_sync_status_changed(this->cache_status));
                }

                // and terminate the loop and go to the sector pages
                break;
            }
        }
    }

    qDebug() << "Done syncing.";
    emit(sync_complete());
}
