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

#include "mainwindow.h"

/**
 * @brief MainWindow
 * @param parent
 */
MainWindow::MainWindow(QWidget *parent)
    : QMainWindow(parent) {

    QWidget* container = new QWidget();
    this->setCentralWidget(container);
    QHBoxLayout* layout = new QHBoxLayout();
    container->setLayout(layout);

    // add hex editor widget
    QWidget* container_widget = new QWidget();
    layout->addWidget(container_widget);
    QVBoxLayout* container_layout = new QVBoxLayout();
    container_widget->setLayout(container_layout);
    this->label_selected_file = new QLabel();
    container_layout->addWidget(this->label_selected_file);
    this->hex_widget = new QHexView();
    this->hex_widget->setMinimumWidth(680);
    this->hex_widget->setMaximumWidth(680);
    container_layout->addWidget(this->hex_widget);

    // add widget for containing files
    this->filetable = new QTableWidget();
    this->filetable->setMinimumWidth(440);
    layout->addWidget(this->filetable);

    // create widget for writing data
    QWidget* right_container = new QWidget();
    QVBoxLayout* right_layout = new QVBoxLayout();
    right_container->setLayout(right_layout);
    layout->addWidget(right_container);

    // build interfaces
    this->build_serial_interface_menu(right_layout);
    this->build_operations_menu(right_layout);
    this->build_filedata_interface(right_layout);
    this->build_fat_capacity_interface(right_layout);

    // add padding frame on RHS
    QFrame* padding_frame = new QFrame();
    right_layout->addWidget(padding_frame);
    padding_frame->setSizePolicy(QSizePolicy(QSizePolicy::MinimumExpanding, QSizePolicy::MinimumExpanding));

    // add compile information
    this->label_compile_data = new QLabel(tr("<b>Build:</b><br>Compile time: %1<br>Git id: %2").arg(__DATE__).arg(GIT_HASH));
    right_layout->addWidget(this->label_compile_data);

    this->setMinimumWidth(1000);
    this->setMinimumHeight(700);

    this->create_dropdown_menu();

    // set button connections
    connect(this->button_scan_ports, SIGNAL (released()), this, SLOT (scan_com_devices()));
    connect(this->button_select_serial, SIGNAL (released()), this, SLOT (select_com_port()));

    // set icon and window title
    this->setWindowIcon(QIcon(":/assets/icon/icon_128px.png"));
    this->setWindowTitle(PROGRAM_NAME);
}

/**
 * @brief Default destructor method
 */
MainWindow::~MainWindow() {
}

/**
 * @brief Create drop-down menus
 */
void MainWindow::create_dropdown_menu() {
    QMenuBar* menubar = new QMenuBar();

    // add drop-down menus
    QMenu *menu_file = menubar->addMenu(tr("&File"));
    QMenu *menu_tools = menubar->addMenu(tr("&Tools"));
    QMenu *menu_help = menubar->addMenu(tr("&Help"));

    // actions for file menu
    QAction *action_save = new QAction(menu_file);
    QAction *action_quit = new QAction(menu_file);
    action_save->setText(tr("Save"));
    action_save->setShortcuts(QKeySequence::Save);
    action_quit->setText(tr("Quit"));
    action_quit->setShortcuts(QKeySequence::Quit);
    menu_file->addAction(action_save);
    menu_file->addAction(action_quit);

    // actions for tools menu
    QAction *action_run = new QAction(menu_tools);
    action_run->setText(tr("Run file"));
    menu_tools->addAction(action_run);
    QAction *action_list = new QAction(menu_tools);
    action_list->setText(tr("List programs"));
    menu_tools->addAction(action_list);
    this->action_add_file = new QAction(menu_tools);
    this->action_add_file->setText(tr("Add program"));
    this->action_add_file->setEnabled(false);
    menu_tools->addAction(this->action_add_file);

    // actions for help menu
    QAction *action_about = new QAction(menu_help);
    action_about->setText(tr("About"));
    menu_help->addAction(action_about);

    // connect actions file menu
    connect(action_run, &QAction::triggered, this, &MainWindow::slot_run);
    connect(action_list, &QAction::triggered, this, &MainWindow::slot_list);
    connect(action_add_file, &QAction::triggered, this, &MainWindow::slot_add_program);
    connect(action_save, &QAction::triggered, this, &MainWindow::slot_save);
    connect(action_about, &QAction::triggered, this, &MainWindow::slot_about);
    connect(action_quit, &QAction::triggered, this, &MainWindow::exit);

    this->setMenuBar(menubar);
}

/**
 * @brief Build GUI showing serial port interface
 * @param layout position where to put this part of the GUI
 */
void MainWindow::build_serial_interface_menu(QVBoxLayout* target_layout) {
    // create interface for serial ports
    QGroupBox* serial_container = new QGroupBox("Serial interface");
    serial_container->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
    QVBoxLayout *layout_serial_vertical = new QVBoxLayout();
    serial_container->setLayout(layout_serial_vertical);
    QHBoxLayout *serial_layout = new QHBoxLayout();
    target_layout->addWidget(serial_container);
    QWidget* container_serial_interface_selector = new QWidget();
    container_serial_interface_selector->setLayout(serial_layout);
    layout_serial_vertical->addWidget(container_serial_interface_selector);
    QLabel* comportlabel = new QLabel(tr("COM port"));
    serial_layout->addWidget(comportlabel);
    this->combobox_serial_ports = new QComboBox(this);
    serial_layout->addWidget(this->combobox_serial_ports);
    this->button_scan_ports = new QPushButton(tr("Scan"));
    serial_layout->addWidget(this->button_scan_ports);
    this->button_select_serial = new QPushButton(tr("Select"));
    this->button_select_serial->setEnabled(false);
    serial_layout->addWidget(this->button_select_serial);

    // create interface for currently selected com port
    QWidget* serial_selected_container = new QWidget();
    QHBoxLayout *serial_selected_layout = new QHBoxLayout();
    serial_selected_container->setLayout(serial_selected_layout);
    this->label_serial = new QLabel(tr("Please select a COM port from the menu above"));
    serial_selected_layout->addWidget(this->label_serial);
    this->label_board_id = new QLabel();
    serial_selected_layout->addWidget(this->label_board_id);
    layout_serial_vertical->addWidget(serial_selected_container);
}

/**
 * @brief Build GUI showing serial port interface
 * @param layout position where to put this part of the GUI
 */
void MainWindow::build_operations_menu(QVBoxLayout* target_layout) {
    // create toplevel interface
    QGroupBox* container = new QGroupBox("Operations");
    container->setSizePolicy(QSizePolicy::Minimum, QSizePolicy::Minimum);
    QVBoxLayout *layout = new QVBoxLayout();
    container->setLayout(layout);

    // add chip label
    this->label_chip_type = new QLabel("");
    layout->addWidget(this->label_chip_type);

    // add individual buttons here
    this->button_identify_chip = new QPushButton("Identify chip");
    this->button_read_rom = new QPushButton("Access FAT");

    layout->addWidget(this->button_identify_chip);
    layout->addWidget(this->button_read_rom);

    this->button_identify_chip->setEnabled(false);
    this->button_read_rom->setEnabled(false);

    connect(this->button_identify_chip, SIGNAL(released()), this, SLOT(read_chip_id()));
    connect(this->button_read_rom, SIGNAL(released()), this, SLOT(slot_access_fat()));

    target_layout->addWidget(container);
    this->progress_bar_load = new QProgressBar();
    target_layout->addWidget(this->progress_bar_load);
}

/**
 * @brief Build filedata interface
 * @param layout position where to put this part of the GUI
 */
void MainWindow::build_filedata_interface(QVBoxLayout* target_layout) {
    // placeholder for file information
    QGroupBox* file_groupbox = new QGroupBox("File information");
    target_layout->addWidget(file_groupbox);
    this->label_filename = new QLabel("");
    this->label_extension = new QLabel("");
    this->label_filesize = new QLabel("");
    this->label_startlocation = new QLabel("");
    this->label_checksums = new QLabel("");
    this->blockmap = new BlockMap();
    QVBoxLayout* layout_files = new QVBoxLayout();
    file_groupbox->setLayout(layout_files);
    layout_files->addWidget(this->label_filename);
    layout_files->addWidget(this->label_extension);
    layout_files->addWidget(this->label_filesize);
    layout_files->addWidget(this->label_startlocation);
    layout_files->addWidget(this->label_checksums);
    layout_files->addWidget(this->blockmap);
}

/**
 * @brief Build filedata interface
 * @param layout position where to put this part of the GUI
 */
void MainWindow::build_fat_capacity_interface(QVBoxLayout* target_layout) {
    // placeholder for file information
    QGroupBox* groupbox = new QGroupBox("ROM capacity");
    target_layout->addWidget(groupbox);
    this->progress_bar_capacity = new QProgressBar();
    this->progress_bar_capacity->setMinimum(0);
    QVBoxLayout* layout = new QVBoxLayout();
    groupbox->setLayout(layout);
    layout->addWidget(this->progress_bar_capacity);
}

/**
 * @brief Verify whether the chip is correct before flashing
 */
void MainWindow::verify_chip() {
    // check whether the same chip is still in the socket
    qDebug() << "Trying to read chip id from: " << this->serial_interface->get_port().c_str();
    this->serial_interface->open_port();
    uint16_t chip_id = this->serial_interface->get_chip_id();
    this->serial_interface->close_port();

    qDebug() << "Verifying chip size.";
    if((chip_id >> 8 & 0xFF) == 0xBF) {
        switch(chip_id & 0xFF) {
            case 0xB5:
                if(this->num_blocks != 128*1024/256) {
                    throw std::runtime_error("Different chip in socket.");
                } else {
                    qDebug() << "Valid chip size for SST39SF010 found.";
                }
            break;
            case 0xB6:
                if(this->num_blocks != 256*1024/256) {
                    throw std::runtime_error("Different chip in socket.");
                } else {
                    qDebug() << "Valid chip size for SST39SF020 found.";
                }
            break;
            case 0xB7:
                if(this->num_blocks != 512*1024/256) {
                    throw std::runtime_error("Different chip in socket.");
                } else {
                    qDebug() << "Valid chip size for SST39SF040 found.";
                }
            break;
            default:
                throw std::runtime_error("Unknown chip id");
            break;
        }
    } else {
        throw std::runtime_error("Unknown chip id");
    }
}

/**
 * @brief Show a window with an error message
 * @param errormsg
 */
void MainWindow::raise_error_window(QMessageBox::Icon icon, const QString errormsg) {
    QMessageBox msg_box;
    msg_box.setIcon(icon);
    msg_box.setText(errormsg);
    msg_box.setWindowIcon(QIcon(":/assets/icon/icon_128px.png"));
    msg_box.exec();
}

/**
 * @brief Read files from FAT and produce list
 */
void MainWindow::index_files() {
    this->fat->read_files();
    this->filetable->clear();
    this->filetable->setRowCount(0);

    this->filetable->setColumnCount(6);
    this->filetable->setColumnWidth(0, 140);
    this->filetable->setColumnWidth(1, 50);
    this->filetable->setColumnWidth(2, 30);
    this->filetable->setColumnWidth(3, 30);
    this->filetable->setColumnWidth(4, 60);
    this->filetable->setColumnWidth(5, 60);
    this->filetable->setHorizontalHeaderLabels({
        "Filename",
        "Size",
        "",
        "",
        "Open",
        "Delete"
    });
    this->filetable->setStyleSheet("font: 8px \"Courier\";");

    QTableWidgetItem *item;
    for(unsigned int i=0; i<this->fat->get_num_files(); i++) {
        const auto file = this->fat->get_file_metadata(i);
        this->filetable->insertRow(i);
        this->filetable->setRowHeight(i, 15);

        // filename
        item = new QTableWidgetItem(QString::fromUtf8(file.filename, 16));
        item->setTextAlignment(Qt::AlignLeft|Qt::AlignVCenter);
        this->filetable->setItem(i, 0, item);

        // size
        item = new QTableWidgetItem(tr("%1").arg(file.size));
        item->setTextAlignment(Qt::AlignRight|Qt::AlignVCenter);
        this->filetable->setItem(i, 1, item);

        // bank
        item = new QTableWidgetItem(tr("%1").arg(file.startbank));
        item->setTextAlignment(Qt::AlignRight|Qt::AlignVCenter);
        this->filetable->setItem(i, 2, item);

        // block
        item = new QTableWidgetItem(tr("%1").arg(file.startblock));
        item->setTextAlignment(Qt::AlignRight|Qt::AlignVCenter);
        this->filetable->setItem(i, 3, item);

        // select button
        QPushButton* button_select = new QPushButton("Open");
        button_select->setProperty("row", QVariant(i));
        button_select->setProperty("operation", QVariant("open"));
        this->filetable->setCellWidget(i, 4, button_select);
        connect(button_select, SIGNAL(released()), this, SLOT(slot_select_file_button()));

        // delete button
        QPushButton* button_delete = new QPushButton("Delete");
        button_delete->setProperty("row", QVariant(i));
        button_delete->setProperty("operation", QVariant("delete"));
        this->filetable->setCellWidget(i, 5, button_delete);
        connect(button_delete, SIGNAL(released()), this, SLOT(slot_select_file_button()));
    }

    this->button_identify_chip->setEnabled(true);
    this->progress_bar_capacity->setValue(this->fat->get_number_occupied_blocks());
}

/****************************************************************************
 *  SIGNALS :: COMMUNICATION INTERFACE ROUTINES
 ****************************************************************************/

/**
 * @brief Scan all communication ports to populate drop-down box
 */
void MainWindow::scan_com_devices() {
    // clear all previous data
    this->combobox_serial_ports->clear();
    this->port_identifiers.clear();

    // pattern to recognise COM PORTS (same ids as Raspberry Pi Pico)
    static const std::vector<std::pair<uint16_t, uint16_t> > patterns = {
        std::make_pair<uint16_t, uint16_t>(0x2E8A, 0x0A),     // Raspberry PICO
        //std::make_pair<uint16_t, uint16_t>(0x2341, 0x36),   // Arduino Leonardo / 32u4
        //std::make_pair<uint16_t, uint16_t>(0x0403, 0x6001)  // FTDI FT232RL

    };

    // get communication devices
    QSerialPortInfo serial_port_info;
    QList<QSerialPortInfo> port_list = serial_port_info.availablePorts();
    std::unordered_map<std::string, std::pair<uint16_t, uint16_t> > ports;
    QStringList device_descriptors;
    qInfo() << "Discovered COM ports.";
    for(int i=0; i<port_list.size(); i++) {
        auto ids = std::make_pair<uint16_t,uint16_t>(port_list[i].vendorIdentifier(), port_list[i].productIdentifier());
        for(int j=0; j<patterns.size(); j++) {
            if(ids == patterns[j]) {
                ports.emplace(port_list[i].portName().toStdString(), ids);
                device_descriptors.append(port_list[i].description());
                qInfo() << port_list[i].portName().toStdString().c_str()
                        << QString("pid=0x%1, vid=0x%2,").arg(port_list[i].vendorIdentifier(),2,16).arg(port_list[i].productIdentifier(),2,16).toStdString().c_str()
                        << QString("descriptor=\"%1\",").arg(port_list[i].description()).toStdString().c_str()
                        << QString("serial=\"%1\"").arg(port_list[i].serialNumber()).toStdString().c_str();
            }
        }
    }

    // populate drop-down menu with valid ports
    for(const auto& item : ports) {
        this->combobox_serial_ports->addItem(item.first.c_str());
        this->port_identifiers.push_back(item.second);
    }

    // if more than one option is available, enable the button
    if(this->combobox_serial_ports->count() > 0) {
        this->button_select_serial->setEnabled(true);
    }


    if(port_identifiers.size() == 1) {
        statusBar()->showMessage(tr("Auto-selecting ") + this->combobox_serial_ports->itemText(0) + tr(" (vid and pid match board)."));
        this->combobox_serial_ports->setCurrentIndex(0);
        this->select_com_port();
    } else if(port_identifiers.size() > 1) {
        QMessageBox msg_box;
        msg_box.setIcon(QMessageBox::Warning);
        msg_box.setText(tr(
              "There are at least %1 devices that share the same id. Please ensure that only a single programmer device is plugged in."
              " If multiple devices are plugged in, ensure you select the correct port. Please also note that the device id overlaps"
              " with the one from the Raspberry Pi Pico. If you have a Raspberry Pi Pico or compatible device plugged in,"
              " take care to unplug it or carefully select the correct port."
        ).arg(port_identifiers.size()));
        msg_box.setWindowIcon(QIcon(":/assets/icon/icon_128px.png"));
        msg_box.exec();
    } else {
        QMessageBox msg_box;
        msg_box.setIcon(QMessageBox::Warning);
        msg_box.setText("Could not find a communication port with a matching id. Please make sure the programmer device is plugged in.");
        msg_box.setWindowIcon(QIcon(":/assets/img/icon_128px.png"));
        msg_box.exec();
    }
}

/**
 * @brief Select communication port for serial to 32u4
 */
void MainWindow::select_com_port() {
    this->serial_interface = std::make_shared<SerialInterface>(this->combobox_serial_ports->currentText().toStdString());

    this->serial_interface->open_port();
    std::string board_info = this->serial_interface->get_board_info();
    this->serial_interface->close_port();
    this->label_serial->setText(tr("Port: ") + this->combobox_serial_ports->currentText());
    this->label_board_id->setText(tr("Board id: ") + tr(board_info.c_str()));
    this->button_identify_chip->setEnabled(true);
}

/**
 * @brief Run a .cas file
 */
void MainWindow::slot_run() {
    qDebug() << "Running machine code as CAS...";
    if(this->hex_widget->get_data().size() == 0) {
        qDebug() << "Nothing here, quitting.";
        return;
    }

    ThreadRun* runthread = new ThreadRun();
    runthread->set_mcode(this->fat->create_cas_file(this->selected_file));
    runthread->set_process_configuration(ThreadRun::ProcessConfiguration::MCODE_AS_CAS);
    connect(runthread, SIGNAL(signal_run_complete(void*)), this, SLOT(slot_run_complete(void*)));
    runthread->start();
}

/**
 * @brief Run a .cas file
 */
void MainWindow::slot_list() {
    for(unsigned int i=0; i<this->fat->get_num_files(); i++) {
        const auto& file = this->fat->get_file_metadata(i);
        qDebug() << tr("%1 %2 %3").arg(QString::fromUtf8(file.filename, 16))
                                  .arg(file.startbank)
                                  .arg(file.startblock);
    }
}

/**
 * @brief Add a program to the ROM
 */
void MainWindow::slot_add_program() {
    QString filename = QFileDialog::getOpenFileName(this, tr("Open file"), tr("roms (*.CAS; *.cas)"));
    QFile file(filename);

    if(file.exists() && file.open(QIODevice::ReadOnly)) {
        QByteArray data = file.readAll();
        QByteArray header = data.mid(0x30, 0x20);

        char filename[16];
        memcpy(filename, header.data() + 0x06, 8);
        memcpy(&filename[8], header.data() + 0x17, 8);

        uint16_t filesize = (uint8_t)header[0x02] + (uint8_t)header[0x03] * 256;
        uint8_t nrblocks = (uint8_t)header[0x1F];

        QMessageBox::StandardButton reply = QMessageBox::question(
            this,
            "Add program?",
            tr("Are you sure you want to commit this program?\n%1\n%2 bytes (%3 blocks)")
                    .arg(QString::fromUtf8(filename, 16))
                    .arg(filesize)
                    .arg(nrblocks),
            QMessageBox::Yes | QMessageBox::No
        );

        if (reply == QMessageBox::Yes) {
            QByteArray romdata;
            for(unsigned int i=0; i<nrblocks; i++) {
                romdata.append(data.mid((i*0x500)+0x100, 0x400));
            }

            this->fat->add_file(header, romdata);
            this->index_files();
        } else {
            return;
        }
    }
}

/**
 * @brief Open a binary file
 */
void MainWindow::slot_save() {
    // do nothing if data size is zero
    auto data = this->hex_widget->get_data();
    if(data.size() == 0) {
        return;
    }

    QString suggested_filename = this->fat->build_filename(this->selected_file);
    QString filename = QFileDialog::getSaveFileName(this, tr("Save File"), suggested_filename, tr("roms (*.CAS *.cas)"));

    // do nothing if user has cancelled
    if(filename.isEmpty()) {
        return;
    }

    QFile file(filename);
    file.open(QIODevice::WriteOnly);
    file.write(this->fat->create_cas_file(this->selected_file));
    file.close();
}

/**
 * @brief Show an about window
 */
void MainWindow::slot_about() {
    QMessageBox message_box;
        //message_box.setStyleSheet("QLabel{min-width: 250px; font-weight: normal;}");
        message_box.setText(PROGRAM_NAME
                            " version "
                            PROGRAM_VERSION
                            ".\n\nAuthor:\nIvo Filot <ivo@ivofilot.nl>\n\n"
                            PROGRAM_NAME " is licensed under the GPLv3 license.\n\n"
                            PROGRAM_NAME " is dynamically linked to Qt, which is licensed under LGPLv3.\n");
        message_box.setIcon(QMessageBox::Information);
        message_box.setWindowTitle("About " + tr(PROGRAM_NAME));
        message_box.setWindowIcon(QIcon(":/assets/icon/icon_128px.png"));
        message_box.exec();
}

/**
 * @brief      Close the application
 */
void MainWindow::exit() {
    QApplication::quit();
}

void MainWindow::load_default_image() {
    QString image = sender()->property("image_name").toString();
    qDebug() << "Loading default image: " << image;

    QString path = ":/assets/roms/" + image;
    QFile file(path);
    file.open(QIODevice::ReadOnly);
    if(file.exists()) {
        QByteArray data = file.readAll();
        this->hex_widget->setData(new QHexView::DataStorageArray(data));
    }
}

/****************************************************************************
 *  SIGNALS :: READ ROM ROUTINES
 ****************************************************************************/

/**
 * @brief Read data from chip
 */
void MainWindow::read_chip_id() {
    statusBar()->showMessage("Reading from chip, please wait...");

    try {
        qDebug() << "Trying to read chip id from: " << this->serial_interface->get_port().c_str();
        this->serial_interface->open_port();
        uint16_t chip_id = this->serial_interface->get_chip_id();
        this->serial_interface->close_port();

        qDebug() << tr("Reading 0x%1 0x%2").arg((uint16_t)chip_id >> 8, 2, 16, QChar('0')).arg((uint8_t)chip_id & 0xFF, 2, 16, QChar('0'));
        std::string chip_id_str = tr("0x%1%2").arg((uint16_t)chip_id >> 8, 2, 16, QChar('0')).arg((uint8_t)chip_id & 0xFF, 2, 16, QChar('0')).toStdString();
        if((chip_id >> 8 & 0xFF) == 0xBF) {
            switch(chip_id & 0xFF) {
                case 0xB5:
                    this->num_blocks = 128*1024/256;
                    this->progress_bar_load->setMaximum(this->num_blocks);
                    this->progress_bar_capacity->setMaximum(60*2);
                    statusBar()->showMessage("Identified a SST39SF010 chip");
                    this->label_chip_type->setText("ROM chip: SST39SF010");
                break;
                case 0xB6:
                this->num_blocks = 256*1024/256;
                    this->progress_bar_load->setMaximum(this->num_blocks);
                    this->progress_bar_capacity->setMaximum(60*4);
                    statusBar()->showMessage("Identified a SST39SF020 chip");
                    this->label_chip_type->setText("ROM chip: SST39SF020");
                break;
                case 0xB7:
                    this->num_blocks = 512*1024/256;
                    this->progress_bar_load->setMaximum(this->num_blocks);
                    this->progress_bar_capacity->setMaximum(60*8);
                    statusBar()->showMessage("Identified a SST39SF040 chip");
                    this->label_chip_type->setText("ROM chip: SST39SF040");
                break;
                default:
                    throw std::runtime_error("Unknown chip id: " + chip_id_str);
                break;
            }
        } else {
            throw std::runtime_error("Unknown chip id: " + chip_id_str);
        }

        this->progress_bar_load->reset();
        this->filetable->clear();
        this->filetable->setColumnCount(0);
        this->filetable->setRowCount(0);
        this->button_read_rom->setEnabled(true);
    } catch (const std::exception& e) {
        QMessageBox msg_box;
        msg_box.setIcon(QMessageBox::Warning);
        msg_box.setText(tr("The chip id does not match the proper value for a SST39SF0x0 chip. Please ensure "
                           "that a correct SST39SF0x0 chip is inserted. If so, resocket the chip and try again.\n\nError message: %1.").arg(e.what()));
        msg_box.setWindowIcon(QIcon(":/assets/icon/icon_128px.png"));
        msg_box.exec();
    }
}

/**
 * @brief Slot to accept when a block is ready
 */
void MainWindow::read_operation(int item, int total) {
    this->progress_bar_load->setValue(item+1);
    this->progress_bar_load->setRange(0, total);
}

/**
 * @brief Slot to accept when a block is ready
 */
void MainWindow::message(QString str) {
    statusBar()->showMessage(str);
}

/****************************************************************************
 *  SIGNALS :: FAT ROUTINES
 ****************************************************************************/

/**
 * @brief Access chip and parse file system
 */
void MainWindow::slot_access_fat() {
    this->button_read_rom->setEnabled(false);
    this->button_identify_chip->setEnabled(false);

    // remove old FAT object if set
    if(this->fat != nullptr) {
        delete this->fat;
    }

    // build new FAT object
    this->fat = new FileAllocationTable();  // recreate
    this->fat->set_serial_interface(this->serial_interface);

    // connect signals
    connect(this->fat, SIGNAL(read_operation(int,int)), this, SLOT(read_operation(int,int)));
    connect(this->fat, SIGNAL(message(QString)), this, SLOT(message(QString)));

    this->index_files();
    this->action_add_file->setEnabled(true);
}

/**
 * @brief Select a new file
 */
void MainWindow::slot_select_file(int row) {
    qDebug() << "Selecting file: " << row << " / " << this->fat->get_num_files();
    if(row >= 0 && row < this->fat->get_num_files()) {
        auto file = this->fat->get_file(row);

        this->label_filename->setText("Filename: " + QString::fromUtf8(file.filename, 16));
        this->label_selected_file->setText(QString::fromUtf8(file.filename, 16));
        this->label_extension->setText("Extension: " + QString::fromUtf8(file.extension, 3));
        this->label_filesize->setText(tr("Filesize: %1 bytes").arg(file.size));
        this->label_startlocation->setText(tr("Start location: Bank %1 / Block %2").arg(file.startbank).arg(file.startblock));

        auto checksums = this->fat->get_checksum_pairs(row);
        QString checksumstr = "Checksums: ";
        for(const auto& p : checksums) {
            if(p.first == p.second) {
                checksumstr += tr("<font color=\"green\">0x%1</font> ").arg(p.first, 4, 16, QLatin1Char('0'));
            } else {
                checksumstr += tr("<font color=\"red\">0x%1</font> ").arg(p.second, 4, 16, QLatin1Char('0'));
            }
        }
        this->label_checksums->setText(checksumstr);
        this->label_checksums->setMaximumWidth(300);
        this->label_checksums->setWordWrap(true);

        // create image of block locations
        this->blockmap->set_blocklist(file.blocks);

        // set data in hexviewer
        this->hex_widget->setData(new QHexView::DataStorageArray(file.data));
    }
}

/**
 * @brief Select a file via pushbutton
 */
void MainWindow::slot_select_file_button() {
    QPushButton* button_sender = qobject_cast<QPushButton*>(sender());
    int row = button_sender->property("row").toInt();
    QString operation =  button_sender->property("operation").toString();
    qDebug() << row << operation;

    if(operation == "open") {
        this->slot_select_file(row);
        this->selected_file = row;
    }
}
