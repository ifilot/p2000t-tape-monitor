#include "fileallocationtable.h"

FileAllocationTable::FileAllocationTable() {}

void FileAllocationTable::read_files() {
    this->serial_interface->open_port();

    // loop over all programs and capture starting blocks
    for(unsigned int bank=0; bank<8; bank++) {
        QByteArray data = this->serial_interface->read_block(bank * 0x100);
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

        QByteArray meta = this->serial_interface->read_block(saddr);
        QByteArray metadata = meta.mid(offset, 0x40);
        std::string description = (metadata.mid(0x26,8) + metadata.mid(0x37,8)).toStdString();

        File file;
        memcpy(file.filename, description.c_str(), 16);
    }

    this->serial_interface->close_port();
}
