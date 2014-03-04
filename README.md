Pebbleash
=========

The word `Pebbleash` is a portmanteau of the words `pebble` and `leash`. Pebble is a highly popular smartwatch and Pebbleash is a utility app for it. It monitors the strength of connection between an iDevice and a Pebble smartwatch, and notifies the Pebble smartwatch if the distance, as indicated by the strength of connection, between them is far enough.

User Interface
--------------

![Pebbleash UI](http://n3rd4n1.github.io/images/screenshot/Pebbleash/pebbleash-ui.png)

Icon Badge Indicator
--------------------

<img src="http://n3rd4n1.github.io/images/screenshot/Pebbleash/icon-off.png" width="120px" height="120px" />
> Pebbleash is either off or is unable to stay active in the background.

<br>
<img src="http://n3rd4n1.github.io/images/screenshot/Pebbleash/icon-connecting.png" width="120px" height="120px" />
> Pebbleash is either actively looking for a Pebble or is connecting to a Pebble.

<br>
<img src="http://n3rd4n1.github.io/images/screenshot/Pebbleash/icon-connected.png" width="120px" height="120px" />
> Pebbleash is connected to a Pebble.

In-Switch Indicator
-------------------

![Off](http://n3rd4n1.github.io/images/screenshot/Pebbleash/disabled-off.png)

> `Off`

> Tap to turn on.

<br>
![Disconnected](http://n3rd4n1.github.io/images/screenshot/Pebbleash/indicator-disconnected.png)

> `Disconnected`

> Tip: Turn on Bluetooth.

<br>
![Searching](http://n3rd4n1.github.io/images/screenshot/Pebbleash/indicator-searching.png)

> `Searching`

> Tip: Connect a Pebble via the Pebble App. If one is already connected, and it stays in this state for some time, [reconnect the Pebble](#reconnect).

<br>
![Connecting](http://n3rd4n1.github.io/images/screenshot/Pebbleash/indicator-connecting.png)

> `Connecting`

> Tip: If it stays in this state for some time, [reconnect the Pebble](#reconnect).

<br>
![Connected](http://n3rd4n1.github.io/images/screenshot/Pebbleash/indicator-connected.png)

> `Connected`

> Hooray!

<br>
![Warning](http://n3rd4n1.github.io/images/screenshot/Pebbleash/indicator-blink.gif)

> `Warning`

> Tip: Make sure `Settings | Privacy | Location Services` is on and that Pebbleash is authorized to use it.

Reconnecting a Pebble <a name="reconnect"></a>
---------------------

1. Forget Pebble in iDevice
  1. Go to `Settings | Bluetooth`
  2. Under `Devices`, select `Pebble *` then `Forget this Device`
  3. Do the same with `Pebble-LE`
  4. Turn off Bluetooth
  5. Turn on Bluetooth

2. Forget iDevice in Pebble
  1. Go to `Settings | Bluetooth`
  2. Select the paired device then `Forget`
  3. Turn off Bluetooth
  4. Turn on Bluetooth

3. Fully connect Pebble via the Pebble App

