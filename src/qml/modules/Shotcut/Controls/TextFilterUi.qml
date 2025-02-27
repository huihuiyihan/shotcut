/*
 * Copyright (c) 2014-2023 Meltytech, LLC
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
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts
import Shotcut.Controls as Shotcut
import org.shotcut.qml as Shotcut

GridLayout {
    property string rectProperty: 'geometry'
    property string valignProperty: 'valign'
    property string halignProperty: 'halign'
    property string useFontSizeProperty: 'shotcut:usePointSize'
    property string pointSizeProperty: 'shotcut:pointSize'
    property rect filterRect
    property string startValue: '_shotcut:startValue'
    property string middleValue: '_shotcut:middleValue'
    property string endValue: '_shotcut:endValue'
    property var parameterList: [rectProperty, halignProperty, valignProperty, 'size', 'style', 'fgcolour', 'family', 'weight', 'olcolour', 'outline', 'bgcolour', 'pad', useFontSizeProperty]

    function getPosition() {
        return Math.max(producer.position - (filter.in - producer.in), 0);
    }

    function updateFilter(position) {
        if (position !== null) {
            filter.blockSignals = true;
            if (position <= 0 && filter.animateIn > 0)
                filter.set(startValue, filterRect);
            else if (position >= filter.duration - 1 && filter.animateOut > 0)
                filter.set(endValue, filterRect);
            else
                filter.set(middleValue, filterRect);
            filter.blockSignals = false;
        }
        if (filter.animateIn > 0 || filter.animateOut > 0) {
            filter.resetProperty(rectProperty);
            positionKeyframesButton.checked = false;
            if (filter.animateIn > 0) {
                filter.set(rectProperty, filter.getRect(startValue), 0);
                filter.set(rectProperty, filter.getRect(middleValue), filter.animateIn - 1);
            }
            if (filter.animateOut > 0) {
                filter.set(rectProperty, filter.getRect(middleValue), filter.duration - filter.animateOut);
                filter.set(rectProperty, filter.getRect(endValue), filter.duration - 1);
            }
        } else if (!positionKeyframesButton.checked) {
            filter.resetProperty(rectProperty);
            filter.set(rectProperty, filter.getRect(middleValue));
        } else if (position !== null) {
            filter.set(rectProperty, filterRect, position);
        }
    }

    function getPointSize() {
        var pointSize = parseInt(filter.get(pointSizeProperty));
        if (!pointSize) {
            var ratio = fontDialog.selectedFont.pointSize / fontDialog.selectedFont.pixelSize;
            pointSize = filter.get('size') * ratio;
        }
        return pointSize;
    }

    function refreshFontButton() {
        var s = filter.get('family');
        if (filter.getDouble('weight') > 10 * Font.Medium)
            s += ' ' + qsTr('Bold');
        if (filter.get('style') === 'italic')
            s += ' ' + qsTr('Italic');
        if (parseInt(filter.get(useFontSizeProperty)))
            s += ' ' + getPointSize();
        fontButton.text = s;
    }

    function setControls() {
        fgColor.value = filter.get('fgcolour');
        fontButton.text = filter.get('family');
        outlineColor.value = filter.get('olcolour');
        outlineSpinner.value = filter.getDouble('outline');
        bgColor.value = filter.get('bgcolour');
        padSpinner.value = filter.getDouble('pad');
        var align = filter.get(halignProperty);
        if (align === 'left')
            leftRadioButton.checked = true;
        else if (align === 'center' || align === 'middle')
            centerRadioButton.checked = true;
        else if (filter.get(halignProperty) === 'right')
            rightRadioButton.checked = true;
        align = filter.get(valignProperty);
        if (align === 'top')
            topRadioButton.checked = true;
        else if (align === 'center' || align === 'middle')
            middleRadioButton.checked = true;
        else if (align === 'bottom')
            bottomRadioButton.checked = true;
        fontDialog.selectedFont = Qt.font({
                "family": filter.get('family'),
                "pointSize": getPointSize(),
                "italic": filter.get('style') === 'italic',
                "weight": filter.getDouble('weight') / 10
            });
        fontSizeCheckBox.checked = parseInt(filter.get(useFontSizeProperty));
        refreshFontButton();
        setKeyframedControls();
    }

    function setKeyframedControls() {
        var position = getPosition();
        var newValue = filter.getRect(rectProperty, position);
        if (filterRect !== newValue) {
            filterRect = newValue;
            rectX.value = filterRect.x.toFixed();
            rectY.value = filterRect.y.toFixed();
            rectW.value = filterRect.width.toFixed();
            rectH.value = filterRect.height.toFixed();
        }
        var enabled = position <= 0 || (position >= (filter.animateIn - 1) && position <= (filter.duration - filter.animateOut)) || position >= (filter.duration - 1);
        rectX.enabled = enabled;
        rectY.enabled = enabled;
        rectW.enabled = enabled;
        rectH.enabled = enabled;
        positionKeyframesButton.checked = filter.keyframeCount(rectProperty) > 0 && filter.animateIn <= 0 && filter.animateOut <= 0;
    }

    function applyTracking(motionTrackerRow, operation, frame) {
        motionTrackerModel.reset(filter, rectProperty, motionTrackerRow);
        const data = motionTrackerModel.trackingData(motionTrackerRow);
        let previous = null;
        let interval = motionTrackerModel.keyframeIntervalFrames(motionTrackerRow);
        let interpolation = Shotcut.KeyframesModel.SmoothInterpolation;
        data.forEach(i => {
                let current = filter.getRect(rectProperty, frame);
                let x = 0;
                let y = 0;
                if (previous !== null) {
                    x = i.x - previous.x;
                    y = i.y - previous.y;
                }
                switch (operation) {
                case 'relativePos':
                    current.x += x;
                    current.y += y;
                    break;
                case 'offsetPos':
                    current.x -= x;
                    current.y -= y;
                    break;
                case 'absPos':
                    current.x = i.x + i.width / 2 - current.width / 2;
                    current.y = i.y + i.height / 2 - current.height / 2;
                    interpolation = Shotcut.KeyframesModel.LinearInterpolation;
                    break;
                case 'absSizePos':
                    current.x = i.x;
                    current.y = i.y;
                    current.width = i.width;
                    current.height = i.height;
                    interpolation = Shotcut.KeyframesModel.LinearInterpolation;
                    break;
                }
                previous = i;
                filter.set(rectProperty, current, frame, interpolation);
                frame += interval;
            });
    }

    columns: 6

    ButtonGroup {
        id: halignGroup
    }

    ButtonGroup {
        id: valignGroup
    }

    Label {
        text: qsTr('Font')
        Layout.alignment: Qt.AlignRight
    }

    Shotcut.ColorPicker {
        id: fgColor

        eyedropper: false
        alpha: true
        onValueChanged: filter.set('fgcolour', value)
    }

    RowLayout {
        Layout.columnSpan: 4

        Shotcut.Button {
            id: fontButton

            onClicked: {
                if (fontSizeCheckBox.checked)
                    fontDialog.selectedFont.pointSize = getPointSize();
                else
                    fontDialog.selectedFont.pointSize = 48;
                fontDialog.open();
            }

            Shotcut.FontDialog {
                id: fontDialog

                property string fontFamily: ''

                onSelectedFontChanged: {
                    filter.set('family', selectedFont.family);
                    filter.set('weight', 10 * selectedFont.weight);
                    filter.set('style', selectedFont.italic ? 'italic' : 'normal');
                    if (parseInt(filter.get(useFontSizeProperty))) {
                        filter.set('size', selectedFont.pixelSize);
                        filter.set(pointSizeProperty, selectedFont.pointSize);
                    }
                    refreshFontButton();
                }
                onAccepted: fontFamily = selectedFont.family
                onRejected: {
                    filter.set('family', fontFamily);
                    refreshFontButton();
                }
            }
        }

        CheckBox {
            id: fontSizeCheckBox

            text: qsTr('Use font size')
            onCheckedChanged: {
                filter.set(useFontSizeProperty, checked);
                if (checked) {
                    filter.set('size', fontDialog.selectedFont.pixelSize);
                    filter.set(pointSizeProperty, fontDialog.selectedFont.pointSize);
                } else {
                    filter.set('size', profile.height / text.split('\n').length);
                }
                refreshFontButton();
            }
        }
    }

    Label {
        text: qsTr('Outline')
        Layout.alignment: Qt.AlignRight
    }

    Shotcut.ColorPicker {
        id: outlineColor

        eyedropper: false
        alpha: true
        onValueChanged: filter.set('olcolour', value)
    }

    Label {
        text: qsTr('Thickness')
        Layout.alignment: Qt.AlignRight
    }

    Shotcut.DoubleSpinBox {
        id: outlineSpinner

        Layout.minimumWidth: 50
        Layout.columnSpan: 3
        from: 0
        to: 200
        onValueModified: filter.set('outline', value)
    }

    Label {
        text: qsTr('Background')
        Layout.alignment: Qt.AlignRight
    }

    Shotcut.ColorPicker {
        id: bgColor

        eyedropper: false
        alpha: true
        onValueChanged: filter.set('bgcolour', value)
    }

    Label {
        text: qsTr('Padding')
        Layout.alignment: Qt.AlignRight
    }

    Shotcut.DoubleSpinBox {
        id: padSpinner

        Layout.minimumWidth: 50
        Layout.columnSpan: 3
        from: 0
        to: 100
        onValueModified: filter.set('pad', value)
    }

    Label {
        text: qsTr('Position')
        Layout.alignment: Qt.AlignRight
    }

    RowLayout {
        Layout.columnSpan: 3

        Shotcut.DoubleSpinBox {
            id: rectX

            Layout.minimumWidth: 100
            horizontalAlignment: Qt.AlignRight
            decimals: 0
            stepSize: 1
            from: -1e+09
            to: 1e+09
            onValueModified: {
                if (filterRect.x !== value) {
                    filterRect.x = value;
                    updateFilter(getPosition());
                }
            }
        }

        Label {
            text: ','
            Layout.minimumWidth: 20
            horizontalAlignment: Qt.AlignHCenter
        }

        Shotcut.DoubleSpinBox {
            id: rectY

            Layout.minimumWidth: 100
            horizontalAlignment: Qt.AlignRight
            decimals: 0
            stepSize: 1
            from: -1e+09
            to: 1e+09
            onValueModified: {
                if (filterRect.y !== value) {
                    filterRect.y = value;
                    updateFilter(getPosition());
                }
            }
        }
    }

    Shotcut.UndoButton {
        onClicked: {
            rectX.value = rectY.value = 0;
            filterRect.x = filterRect.y = 0;
            updateFilter(getPosition());
        }
    }

    Shotcut.KeyframesButton {
        id: positionKeyframesButton

        Layout.rowSpan: 2
        onToggled: {
            if (checked) {
                filter.blockSignals = true;
                filter.clearSimpleAnimation(rectProperty);
                filter.blockSignals = false;
                filter.set(rectProperty, filterRect, getPosition());
            } else {
                filter.blockSignals = true;
                filter.resetProperty(rectProperty);
                filter.blockSignals = false;
                filter.set(rectProperty, filterRect);
            }
            checked = filter.keyframeCount(rectProperty) > 0 && filter.animateIn <= 0 && filter.animateOut <= 0;
        }
    }

    Label {
        text: qsTr('Size')
        Layout.alignment: Qt.AlignRight
    }

    RowLayout {
        Layout.columnSpan: 3

        Shotcut.DoubleSpinBox {
            id: rectW

            Layout.minimumWidth: 100
            horizontalAlignment: Qt.AlignRight
            decimals: 0
            stepSize: 1
            from: -1e+09
            to: 1e+09
            onValueModified: {
                if (filterRect.width !== value) {
                    filterRect.width = value;
                    updateFilter(getPosition());
                }
            }
        }

        Label {
            text: 'x'
            Layout.minimumWidth: 20
            horizontalAlignment: Qt.AlignHCenter
        }

        Shotcut.DoubleSpinBox {
            id: rectH

            Layout.minimumWidth: 100
            horizontalAlignment: Qt.AlignRight
            decimals: 0
            stepSize: 1
            from: -1e+09
            to: 1e+09
            onValueModified: {
                if (filterRect.height !== value) {
                    filterRect.height = value;
                    updateFilter(getPosition());
                }
            }
        }
    }

    Shotcut.UndoButton {
        onClicked: {
            rectW.value = profile.width;
            rectH.value = profile.height;
            filterRect.width = profile.width;
            filterRect.height = profile.height;
            updateFilter(getPosition());
        }
    }

    Label {
        text: qsTr('Horizontal fit')
        Layout.alignment: Qt.AlignRight
    }

    RadioButton {
        id: leftRadioButton

        text: qsTr('Left')
        ButtonGroup.group: halignGroup
        onClicked: filter.set(halignProperty, 'left')
    }

    RadioButton {
        id: centerRadioButton

        text: qsTr('Center')
        ButtonGroup.group: halignGroup
        onClicked: filter.set(halignProperty, 'center')
    }

    RadioButton {
        id: rightRadioButton

        text: qsTr('Right')
        ButtonGroup.group: halignGroup
        onClicked: filter.set(halignProperty, 'right')
    }

    Shotcut.UndoButton {
        onClicked: {
            centerRadioButton.checked = true;
            filter.set(halignProperty, 'center');
        }
    }

    Item {
        Layout.fillWidth: true
    }

    Label {
        text: qsTr('Vertical fit')
        Layout.alignment: Qt.AlignRight
    }

    RadioButton {
        id: topRadioButton

        text: qsTr('Top')
        ButtonGroup.group: valignGroup
        onClicked: filter.set(valignProperty, 'top')
    }

    RadioButton {
        id: middleRadioButton

        text: qsTr('Middle', 'Text video filter')
        ButtonGroup.group: valignGroup
        onClicked: filter.set(valignProperty, 'middle')
    }

    RadioButton {
        id: bottomRadioButton

        text: qsTr('Bottom')
        ButtonGroup.group: valignGroup
        onClicked: filter.set(valignProperty, 'bottom')
    }

    Shotcut.UndoButton {
        onClicked: {
            bottomRadioButton.checked = true;
            filter.set(valignProperty, 'bottom');
        }
    }

    Item {
        width: 1
    }

    Shotcut.Button {
        Layout.columnSpan: parent.columns - 1
        text: motionTrackerDialog.title
        onClicked: motionTrackerDialog.show()
    }

    Item {
        Layout.fillWidth: true
    }

    Shotcut.MotionTrackerDialog {
        id: motionTrackerDialog
        onAccepted: (motionTrackerRow, operation, startFrame) => applyTracking(motionTrackerRow, operation, startFrame)
        onReset: if (filter.keyframeCount(rectProperty) > 0 && filter.animateIn <= 0 && filter.animateOut <= 0) {
            motionTrackerModel.undo(filter, rectProperty);
            filterRect = filter.getRect(rectProperty, getPosition());
            rectX.value = filterRect.x;
            rectY.value = filterRect.y;
            rectW.value = filterRect.width;
            rectH.value = filterRect.height;
            updateFilter(getPosition());
        }
    }

    Connections {
        function onChanged() {
            setKeyframedControls();
        }

        function onInChanged() {
            updateFilter(null);
        }

        function onOutChanged() {
            updateFilter(null);
        }

        function onAnimateInChanged() {
            updateFilter(null);
        }

        function onAnimateOutChanged() {
            updateFilter(null);
        }

        target: filter
    }

    Connections {
        function onPositionChanged() {
            setKeyframedControls();
        }

        target: producer
    }
}
