#ifndef BLOCKMAP_H
#define BLOCKMAP_H

#include <QWidget>
#include <QPainter>
#include <QDebug>

class BlockMap : public QWidget
{
    Q_OBJECT
private:
    static const unsigned int pixsize = 5;
    static const unsigned int width = 60 * pixsize + 1;
    static const unsigned int height = 8 * pixsize + 1;
    std::vector<std::pair<uint8_t, uint8_t>> blocks;

public:
    explicit BlockMap(QWidget *parent = nullptr);

    void set_blocklist(const std::vector<std::pair<uint8_t, uint8_t>>& _blocks);

    QSize minimumSizeHint() const override;

    QSize sizeHint() const override;

protected:
    void paintEvent(QPaintEvent *event) override;

signals:

};

#endif // BLOCKMAP_H
