# Shared helper: directly control the default microphone's mute state via
# the Windows Core Audio API (IAudioEndpointVolume). More reliable than
# simulating keypresses, since it doesn't depend on any app's keyboard hook.

if (-not ("AudioMute" -as [type])) {
Add-Type -TypeDefinition @"
using System;
using System.Runtime.InteropServices;

[Guid("A95664D2-9614-4F35-A746-DE8DB63617E6"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDeviceEnumerator {
    int NotImpl1();
    int GetDefaultAudioEndpoint(int dataFlow, int role, out IMMDevice ppDevice);
}
[Guid("D666063F-1587-4E43-81F1-B948E807363F"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IMMDevice {
    int Activate(ref Guid iid, int dwClsCtx, IntPtr pActivationParams, [MarshalAs(UnmanagedType.IUnknown)] out object ppInterface);
}
[Guid("5CDF2C82-841E-4546-9722-0CF74078229A"), InterfaceType(ComInterfaceType.InterfaceIsIUnknown)]
interface IAudioEndpointVolume {
    int P00(); // RegisterControlChangeNotify
    int P01(); // UnregisterControlChangeNotify
    int P02(); // GetChannelCount
    int P03(); // SetMasterVolumeLevel
    int P04(); // SetMasterVolumeLevelScalar
    int P05(); // GetMasterVolumeLevel
    int P06(); // GetMasterVolumeLevelScalar
    int P07(); // SetChannelVolumeLevel
    int P08(); // SetChannelVolumeLevelScalar
    int P09(); // GetChannelVolumeLevel
    int P10(); // GetChannelVolumeLevelScalar
    int SetMute([MarshalAs(UnmanagedType.Bool)] bool mute, IntPtr eventContext);
    int GetMute([MarshalAs(UnmanagedType.Bool)] out bool mute);
}
[ComImport, Guid("BCDE0395-E52F-467C-8E3D-C4579291692E")]
class MMDeviceEnumeratorComObject { }

public class AudioMute {
    static readonly Guid IID_IAudioEndpointVolume = new Guid("5CDF2C82-841E-4546-9722-0CF74078229A");

    static IAudioEndpointVolume GetDefaultCaptureVolume() {
        var enumerator = (IMMDeviceEnumerator)new MMDeviceEnumeratorComObject();
        IMMDevice device;
        // eCapture = 1, eMultimedia = 1
        enumerator.GetDefaultAudioEndpoint(1, 1, out device);
        object obj;
        Guid iid = IID_IAudioEndpointVolume;
        device.Activate(ref iid, 23, IntPtr.Zero, out obj);
        return (IAudioEndpointVolume)obj;
    }

    public static bool IsMuted() {
        var vol = GetDefaultCaptureVolume();
        bool muted;
        vol.GetMute(out muted);
        return muted;
    }

    public static void SetMuted(bool mute) {
        var vol = GetDefaultCaptureVolume();
        vol.SetMute(mute, IntPtr.Zero);
    }
}
"@
}
