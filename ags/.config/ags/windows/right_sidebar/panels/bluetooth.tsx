import Gtk from "gi://Gtk?version=4.0"
import { execAsync } from "ags/process"
import { createBinding, createComputed, For } from "gnim"
import AstalBluetooth from "gi://AstalBluetooth?version=0.1"

export default function BluetoothPanel() {
  const bluetooth = AstalBluetooth.get_default()
  if (!bluetooth) return <box />

  const adapter = bluetooth.adapter
  if (!adapter) {
    return <box name="bluetooth" heightRequest={200}>
        <label label="No Bluetooth Adapter" valign={Gtk.Align.CENTER} halign={Gtk.Align.CENTER} />
    </box>
  }

  const devices = createBinding(bluetooth, "devices")
  const connected = createBinding(bluetooth, "isConnected")
  const sortedDevices = createComputed([devices, connected],
    (devs, _) => devs.sort((_, b) => Number(b.paired)).sort((_, b) => Number(b.connected))
  )

  function listItem(device: AstalBluetooth.Device) {
    const devConn = createBinding(device, "connected")
    if (device.name === null) return <box />
    
    const visibleBinding = createComputed([devConn, createBinding(device, "paired")], (c, p) => c || p)
    const status = createComputed([devConn, createBinding(device, "connecting")],
      (c, ing) => ing ? "..." : c ? "Connected" : "Paired")
    const battery = createComputed([devConn, createBinding(device, "batteryPercentage")],
      (c, p) => c && p > 0 ? ` (${Math.floor(p * 100)}%)` : "")

    return <box class="Item">
      <box>
        <image class="icon" pixelSize={24} iconName={device.icon || "help-browser"} />
        <box orientation={Gtk.Orientation.VERTICAL}>
          <box halign={Gtk.Align.START}>
            <label label={device.name} class="Name" />
            <label label={battery} class="Battery" />
          </box>
          <label visible={visibleBinding} class="Status" halign={Gtk.Align.START} label={status} />
        </box>
      </box>
      <box hexpand />
      <box class="Actions">
        <button label="" visible={createBinding(device, "paired").as((p) => !p)} onClicked={() => device.pair()} />
        <button label="󱘖" onClicked={() => device.get_connected() ? device.disconnect_device(null) : device.connect_device(null)} />
      </box>
    </box>
  }

  return <box
    name="bluetooth"
    class="SidebarBluetoothPanel"
    orientation={Gtk.Orientation.VERTICAL}
    // REDUCIDO: De 400 a 200
    heightRequest={200}
  >
    <box>
      <label label="Bluetooth" class="Title" />
      <box hexpand />
      <button
        class="Discover"
        label="󰓦"
        onClicked={() => adapter.discovering ? adapter.stop_discovery() : adapter.start_discovery()}
      />
      <switch active={createBinding(bluetooth, "isPowered")} onActivate={() => execAsync("rfkill toggle bluetooth")} />
    </box>
    <scrolledwindow vexpand class="ItemList">
      <box orientation={Gtk.Orientation.VERTICAL}>
        <For each={sortedDevices}>{(dev) => listItem(dev)}</For>
      </box>
    </scrolledwindow>
  </box>
}
