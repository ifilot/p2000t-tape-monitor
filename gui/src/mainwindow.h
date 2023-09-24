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

#ifndef MAINWINDOW_H
#define MAINWINDOW_H

#include <QMainWindow>
#include <QHBoxLayout>
#include <QVBoxLayout>
#include <QMenuBar>
#include <QApplication>
#include <QPushButton>
#include <QComboBox>
#include <QLabel>
#include <QGroupBox>
#include <QStatusBar>
#include <QMessageBox>
#include <QFile>
#include <QProgressBar>
#include <QTimer>
#include <QElapsedTimer>
#include <QFrame>
#include <QFileDialog>
#include <QListWidget>
#include <QImage>

#include "config.h"
#include "qhexview.h"
#include "serial_interface.h"
#include "readthread.h"
#include "flashthread.h"
#include "dialogslotselection.h"
#include "romsizes.h"
#include "fileallocationtable.h"
#include "blockmap.h"
#include "threadrun.h"

class MainWindow : public QMainWindow
{
    Q_OBJECT

private:
    // widgets
    QHexView* hex_widget;

    // Serial port selection
    QPushButton* button_select_serial;
    QPushButton* button_scan_ports;
    QLabel* label_serial;
    QLabel* label_board_id;
    QComboBox* combobox_serial_ports;
    std::vector<std::pair<uint16_t, uint16_t>> port_identifiers;
    std::shared_ptr<SerialInterface> serial_interface;

    // buttons
    QLabel* label_chip_type;
    QPushButton* button_identify_chip;
    QPushButton* button_read_rom;

    // chip data
    int num_blocks = 0;

    // progress bar
    QProgressBar* progress_bar_load;

    // information on compilation time
    QLabel* label_compile_data;

    // for FAT
    FileAllocationTable* fat = nullptr;
    QListWidget* filelist;
    QLabel* label_filename;
    QLabel* label_extension;
    QLabel* label_filesize;
    QLabel* label_startlocation;
    QLabel* label_checksums;
    BlockMap* blockmap;

public:
    /**
     * @brief MainWindow
     * @param parent
     */
    MainWindow(QWidget *parent = nullptr);

    /**
     * @brief Default destructor method
     */
    ~MainWindow();

private:
    /**
     * @brief Create drop-down menus
     */
    void create_dropdown_menu();

    /**
     * @brief Build GUI showing serial port interface
     * @param layout position where to put this part of the GUI
     */
    void build_serial_interface_menu(QVBoxLayout* target_layout);

    /**
     * @brief Build GUI showing operations to perform
     * @param layout position where to put this part of the GUI
     */
    void build_operations_menu(QVBoxLayout* target_layout);

    /**
     * @brief Build filedata interface
     * @param layout position where to put this part of the GUI
     */
    void build_filedata_interface(QVBoxLayout* target_layout);

    /**
     * @brief Verify whether the chip is correct before flashing
     */
    void verify_chip();

    /**
     * @brief Show a window with an error message
     * @param errormsg
     */
    void raise_error_window(QMessageBox::Icon icon, const QString errormsg);

private slots:
    /**
     * @brief      Close the application
     */
    void exit();

    /**
     * @brief Run a .cas file
     */
    void slot_run();

    /**
     * @brief Save a binary file
     */
    void slot_save();

    /**
     * @brief Show an about window
     */
    void slot_about();

    /****************************************************************************
     *  SIGNALS :: COMMUNICATION INTERFACE ROUTINES
     ****************************************************************************/

    /**
     * @brief Scan all communication ports to populate drop-down box
     */
    void scan_com_devices();

    /**
     * @brief Select communication port for serial to 32u4
     */
    void select_com_port();

    /**
     * @brief Load default image into HexWidget window
     */
    void load_default_image();

    /****************************************************************************
     *  SIGNALS :: READ ROM ROUTINES
     ****************************************************************************/

    /**
     * @brief Read data from chip
     */
    void read_chip_id();

    /**
     * @brief Slot to indicate that a block is about to be read / written
     */
    void read_operation(int item, int total);

    /**
     * @brief Parse message
     * @param str
     */
    void message(QString str);

    /**
     * @brief Access chip and parse file system
     */
    void slot_access_fat();

    /****************************************************************************
     *  SIGNALS :: FILES
     ****************************************************************************/

    /**
     * @brief Select a new file
     */
    void slot_select_file(int row);
};
#endif // MAINWINDOW_H