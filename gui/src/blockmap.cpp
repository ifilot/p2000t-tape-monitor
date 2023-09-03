#include "blockmap.h"

BlockMap::BlockMap(QWidget *parent) : QWidget(parent) {
    this->setBackgroundRole(QPalette::Base);
    this->setAutoFillBackground(true);
    this->setUpdatesEnabled(true);
}

void BlockMap::set_blocklist(const std::vector<std::pair<uint8_t, uint8_t>>& _blocks) {
    this->blocks = _blocks;
    qDebug() << "Set blocklist";
    this->update();
}

QSize BlockMap::minimumSizeHint() const {
    return QSize(this->width, this->height);
}

QSize BlockMap::sizeHint() const {
    return QSize(this->width, this->height);
}

void BlockMap::paintEvent(QPaintEvent *event) {
    QPainter painter(this);
    painter.setPen(QPen(Qt::black));
    painter.setBrush(QBrush(Qt::gray));

    for(unsigned int j=0; j<8; j++) {
        for(unsigned int i=0; i<60; i++) {
            QRect rect(i * this->pixsize,
                       j * this->pixsize,
                       this->pixsize,
                       this->pixsize);
            painter.drawRect(rect);
        }
    }

    painter.setPen(QPen(Qt::black));
    painter.setBrush(QBrush(Qt::green));
    for(const auto& p : this->blocks) {
        QRect rect(p.second * this->pixsize,
                   p.first * this->pixsize,
                   this->pixsize,
                   this->pixsize);
        painter.drawRect(rect);
    }
}
