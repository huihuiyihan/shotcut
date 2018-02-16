/*
 * Copyright (c) 2016-2018 Meltytech, LLC
 * Author: Dan Dennedy <dan@dennedy.org>
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#ifndef QMLPRODUCER_H
#define QMLPRODUCER_H

#include <QObject>
#include <QString>
#include <QVariant>

#include <MltProducer.h>
#include "shotcut_mlt_properties.h"

class QmlProducer : public QObject
{
    Q_OBJECT
    Q_PROPERTY(int in READ in() NOTIFY inChanged)
    Q_PROPERTY(int out READ out() NOTIFY outChanged)
    Q_PROPERTY(int aspectRatio READ aspectRatio() NOTIFY producerChanged)
    Q_PROPERTY(int duration READ duration() NOTIFY producerChanged)
    Q_PROPERTY(QString resource READ resource() NOTIFY producerChanged)
    Q_PROPERTY(QString mlt_service READ mlt_service() NOTIFY producerChanged)
    Q_PROPERTY(QString hash READ hash() NOTIFY producerChanged)
    Q_PROPERTY(QString name READ name() NOTIFY producerChanged)
    Q_PROPERTY(QVariant audioLevels READ audioLevels NOTIFY producerChanged)
    Q_PROPERTY(int fadeIn READ fadeIn NOTIFY producerChanged)
    Q_PROPERTY(int fadeOut READ fadeOut NOTIFY producerChanged)
    Q_PROPERTY(double speed READ speed NOTIFY producerChanged)
    Q_PROPERTY(int position READ position WRITE setPosition NOTIFY positionChanged)

public:
    explicit QmlProducer(QObject *parent = 0);

    int in();
    int out();
    double aspectRatio();
    int duration() { return m_producer.is_valid()? out() - in() + 1 : 0; }
    QString resource();
    QString mlt_service() { return m_producer.is_valid()? m_producer.get("mlt_service") : QString(); }
    QString hash() { return m_producer.is_valid()? m_producer.get(kShotcutHashProperty) : QString(); }
    QString name();
    QVariant audioLevels();
    int fadeIn();
    int fadeOut();
    double speed();
    int position() const { return m_position; }
    void setPosition(int position);
    void seek(int position);
    Mlt::Producer& producer() { return m_producer; }

signals:
    void producerChanged();
    void positionChanged();
    void seeked(int position);
    void inChanged();
    void outChanged();

public slots:
    void setProducer(Mlt::Producer& producer);

private:
    Mlt::Producer m_producer;
    int m_position;
};

#endif // QMLPRODUCER_H
