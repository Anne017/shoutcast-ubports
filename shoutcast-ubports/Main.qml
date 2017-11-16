import QtQuick 2.4
import Ubuntu.Components 1.3
import QtQuick.XmlListModel 2.0
import QtMultimedia 5.6

/*!
    \brief MainView with a Label and Button elements.
*/

import "components/shoutcast.js" as Shoutcast
import "components/Util.js" as Util

import "components"

MainView {
    // objectName for functional testing purposes (autopilot-qt5)
    objectName: "mainView"

    // Note! applicationName needs to match the "name" field of the click manifest
    applicationName: "shoutcast-ubports.wdehoog"

    property string defaultImageSource: "image://theme/icon-m-music"
    property string logoURL: ""
    property string streamMetaText1: ""
    property string streamMetaText2: ""

    width: units.gu(100)
    height: units.gu(75)

    property int currentItem: -1
    property var tuneinBase: {}

    PageStack {
        id: pageStack

        Component.onCompleted: {
            pageStack.push(mainPage)
        }

        Page {
            id: mainPage
            visible: false
            title: i18n.tr("SHOUTcast")

            header: PageHeader {
                id: pageHeader
                title: i18n.tr("SHOUTcast")
                StyleHints {
                    foregroundColor: UbuntuColors.orange
                    backgroundColor: UbuntuColors.porcelain
                    dividerColor: UbuntuColors.slate
                }
            }

            Column {
                spacing: units.gu(1)
                width: parent.width
                anchors.verticalCenter: parent.verticalCenter

                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr("Genre")
                    color: "white"
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("pages/GenrePage.qml") )
                    }
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr("Top 500")
                    color: "white"
                    onClicked: {
                        pageStack.push(Qt.resolvedUrl("pages/Top500Page.qml"))
                        top500Page.reload()
                    }
                }
                Button {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: i18n.tr("Search")
                    color: "white"
                    //onClicked: pause()
                }

                Row {
                    id: playerUI

                    //height: Math.max(imageItem.height, meta.height, playerButtons.height)
                    width: parent.width

                    Image {
                        id: imageItem
                        source: logoURL.length > 0 ? logoURL : defaultImageSource
                        width: units.gu(5)
                        height: width
                        anchors.verticalCenter: parent.verticalCenter
                        fillMode: Image.PreserveAspectFit
                    }

                    Column {
                        id: meta
                        width: parent.width - imageItem.width - playerButton.width
                        anchors.verticalCenter: parent.verticalCenter

                        Text {
                            id: m1
                            //x: Theme.paddingSmall
                            width: parent.width - Theme.paddingSmall
                            color: UbuntuColors.orange
                            textFormat: Text.StyledText
                            //font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                            text: streamMetaText1
                        }
                        Text {
                            id: m2
                            //1dth: parent.width- Theme.paddingSmall
                            anchors.right: parent.right
                            color: UbuntuColors.darkGrey
                            //font.pixelSize: Theme.fontSizeSmall
                            wrapMode: Text.Wrap
                            text: streamMetaText2
                        }

                    }

                    Action {
                          id: playerButton
                          name: "media-playback-start"
                          onTriggered: pause()
                    }

                }
            }

        }
    }

    signal audioBufferFull()
    onAudioBufferFull: play()

    Audio {
        id: audio
        audioRole: Audio.MusicRole
        autoLoad: true
        autoPlay: false

        //onPlaybackStateChanged: app.playbackStateChanged()
        //onSourceChanged: refreshTransportState()

        //onBufferProgressChanged: {
        //    if(bufferProgress == 1.0)
        //        audioBufferFull()
        //}

        onError: {
            console.log("Audio Player error:" + errorString)
            console.log("source: " + source)
            //showErrorDialog(qsTr("Audio Player:") + "\n\n" + errorString)
        }
    }

    function play() {
        console.log("play() audio.source:" + audio.source)
        audio.play()
    }

    function pause() {
        console.log("pause() audio.source:" + audio.source)
        if(audio.playbackState === Audio.PlayingState)
            audio.pause()
        else
            play()
    }

    property var currentStationInfo

    onStationChanged: {
        currentStationInfo = stationInfo
        console.log("set stream:" + stationInfo.stream)
        audio.source = stationInfo.stream
        play()
    }

    signal stationChanged(var stationInfo)
    signal stationChangeFailed(var stationInfo)

    function loadStation(stationId, info, tuneinBase) {
        var m3uBase = tuneinBase["base-m3u"]

        if(!m3uBase) {
            //showErrorDialog(qsTr("Don't know how to retrieve playlist."))
            console.log("Don't know how to retrieve playlist.: \n" + JSON.stringify(tuneinBase))
        }

        var xhr = new XMLHttpRequest
        var playlistUri = Shoutcast.TuneInBase
                + m3uBase
                + "?" + Shoutcast.getStationPart(stationId)
        xhr.open("GET", playlistUri)
        xhr.onreadystatechange = function() {
            if(xhr.readyState === XMLHttpRequest.DONE) {
                var playlist = xhr.responseText;
                console.log("Playlis for stream: \n" + playlist)
                var streamURL
                streamURL = Shoutcast.extractURLFromM3U(playlist)
                console.log("URL: \n" + streamURL)
                if(streamURL.length > 0) {
                    info.stream = streamURL
                    stationChanged(info)
                } else {
                    //showErrorDialog(qsTr("Failed to retrieve stream URL."))
                    console.log("Error could not find stream URL: \n" + playlistUri + "\n" + playlist + "\n")
                    stationChangeFailed(info)
                }
            }
        }
        xhr.send();
    }

    function createTimer(root, interval) {
        return Qt.createQmlObject("import QtQuick 2.0; Timer {interval: " + interval + "; repeat: false; running: true;}", root, "TimeoutTimer");
    }

    function getSearchNowPlayingURI(nowPlayingQuery) {
        if(nowPlayingQuery.length === 0)
            return ""
        var uri = Shoutcast.NowPlayingSearchBase
                  + "?" + Shoutcast.DevKeyPart
                  + "&" + Shoutcast.QueryFormat
                  + "&" + Shoutcast.getLimitPart(500)
        //if(mimeTypeFilter.value === 1)
        //    uri += "&" + Shoutcast.getAudioTypeFilterPart("audio/mpeg")
        //else if(mimeTypeFilter.value === 2)
        //    uri += "&" + Shoutcast.getAudioTypeFilterPart("audio/aacp")
        uri += "&" + Shoutcast.getPlayingPart(nowPlayingQuery)
        return uri
    }

    function getStationByGenreURI(genreId) {
      var uri = Shoutcast.StationSearchBase
                    + "?" + Shoutcast.getGenrePart(genreId)
                    + "&" + Shoutcast.DevKeyPart
                    + "&" + Shoutcast.getLimitPart(500)
                    + "&" + Shoutcast.QueryFormat
        //if(mimeTypeFilter.value === 1)
        //    uri += "&" + Shoutcast.getAudioTypeFilterPart("audio/mpeg")
        //else if(mimeTypeFilter.value === 2)
        //    uri += "&" + Shoutcast.getAudioTypeFilterPart("audio/aacp")
        return uri
    }

}