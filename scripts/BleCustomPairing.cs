// Windows desktop helper for BlePairing.psm1 (compiled on demand into build/pairing).
//
// Plain DeviceInformationPairing.PairAsync() fails within ~40 ms from a desktop
// process that has no pairing UI (observed 2026-09-27 on WINSTONDESKTOP). Custom
// pairing with ConfirmOnly succeeds for the ESP32's Just Works bonding, but the
// PairingRequested event must be answered synchronously, which a PowerShell
// scriptblock cannot do on a WinRT thread. This helper only subscribes the
// handler and returns the native operation, so the caller keeps its existing
// bounded wait / cancellation / postcheck logic.
using System.Collections.Generic;
using Windows.Devices.Enumeration;
using Windows.Foundation;

public static class BleCustomPairing
{
    // Keeps custom-pairing objects (and their handlers) alive until the process exits.
    static readonly List<DeviceInformationCustomPairing> Active = new List<DeviceInformationCustomPairing>();

    public static IAsyncOperation<DevicePairingResult> StartConfirmOnlyPair(DeviceInformation device)
    {
        DeviceInformationCustomPairing custom = device.Pairing.Custom;
        custom.PairingRequested += (sender, args) =>
        {
            if (args.PairingKind == DevicePairingKinds.ConfirmOnly) args.Accept();
        };
        lock (Active) Active.Add(custom);
        return custom.PairAsync(DevicePairingKinds.ConfirmOnly);
    }
}
