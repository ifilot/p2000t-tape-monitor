#ifndef BLOCKMAP_H
#define BLOCKMAP_H

#include <QWidget>
#include <QPainter>
#include <QDebug>
#include <stdexcept>

class BlockMap : public QWidget
{
    Q_OBJECT
private:
    std::vector<std::pair<uint8_t, uint8_t>> blocks;

    unsigned int rows;
    unsigned int columns;
    unsigned int blocksize;
    unsigned int width;
    unsigned int height;
    std::vector<uint8_t> blockvalues;

public:
    BlockMap(unsigned int _colums,
             unsigned int _rows,
             unsigned int _blocksize,
             QWidget *parent = nullptr);

    void set_blocklist(const std::vector<std::pair<uint8_t, uint8_t>>& _blocks, uint8_t nrbanks);

    void set_cache(const std::vector<uint8_t> _cache_status);

    QSize minimumSizeHint() const override;

    QSize sizeHint() const override;

protected:
    void paintEvent(QPaintEvent *event) override;

signals:

};

#endif // BLOCKMAP_H
