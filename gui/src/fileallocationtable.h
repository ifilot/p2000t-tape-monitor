#ifndef FILEALLOCATIONTABLE_H
#define FILEALLOCATIONTABLE_H

#include <memory>
#include "serial_interface.h"

struct File {
    char filename[16];
    char extension[3];
    uint16_t size;
    uint8_t startblock;
    uint8_t startbank;
};

class FileAllocationTable {
private:
    std::shared_ptr<SerialInterface> serial_interface;
    std::vector<std::pair<unsigned int, unsigned int>> progblocks;
    std::vector<File> files;

public:
    FileAllocationTable();

    void set_serial_interface(const std::shared_ptr<SerialInterface>& _serial_interface) {
        this->serial_interface = _serial_interface;
    }

    void read_files();

private:
};

#endif // FILEALLOCATIONTABLE_H
