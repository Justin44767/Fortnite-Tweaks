using System;
using System.Collections.Generic;
using System.ComponentModel;
using System.Runtime.InteropServices;

namespace FortniteTweaks
{
    public static class InputNative
    {
        [StructLayout(LayoutKind.Sequential)]
        public struct FilterKeys
        {
            public uint Size, Flags, Wait, Delay, Repeat, Bounce;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct Gamepad
        {
            public ushort Buttons;
            public byte LeftTrigger, RightTrigger;
            public short LeftX, LeftY, RightX, RightY;
        }

        [StructLayout(LayoutKind.Sequential)]
        public struct GamepadState { public uint Packet; public Gamepad Pad; }

        public sealed class ControllerSample
        {
            public uint Slot;
            public double LeftStickPercent, RightStickPercent, LeftTriggerPercent, RightTriggerPercent;
        }

        [DllImport("user32.dll", EntryPoint = "SystemParametersInfoW", ExactSpelling = true, SetLastError = true)]
        [return: MarshalAs(UnmanagedType.Bool)]
        private static extern bool SystemParametersInfo(uint action, uint size, ref FilterKeys values, uint flags);

        [DllImport("xinput1_4.dll", EntryPoint = "XInputGetState", ExactSpelling = true)]
        private static extern uint XInputGetState(uint index, out GamepadState state);

        public static FilterKeys ReadFilterKeys()
        {
            FilterKeys values = new FilterKeys();
            values.Size = (uint)Marshal.SizeOf(typeof(FilterKeys));
            if (!SystemParametersInfo(0x0032, values.Size, ref values, 0))
                throw new Win32Exception(Marshal.GetLastWin32Error());
            return values;
        }

        public static void WriteFilterKeys(uint flags, uint wait, uint delay, uint repeat, uint bounce)
        {
            FilterKeys values = new FilterKeys();
            values.Size = (uint)Marshal.SizeOf(typeof(FilterKeys));
            values.Flags = flags; values.Wait = wait; values.Delay = delay; values.Repeat = repeat; values.Bounce = bounce;
            // SPI_SETFILTERKEYS; persist for this user and broadcast WM_SETTINGCHANGE.
            if (!SystemParametersInfo(0x0033, values.Size, ref values, 0x0001 | 0x0002))
                throw new Win32Exception(Marshal.GetLastWin32Error());
        }

        public static double StickPercent(short x, short y)
        {
            double dx = x, dy = y;
            return Math.Round(Math.Min(100.0, Math.Sqrt(dx * dx + dy * dy) / 32767.0 * 100.0), 2);
        }

        public static ControllerSample[] ReadControllers()
        {
            List<ControllerSample> samples = new List<ControllerSample>();
            for (uint index = 0; index < 4; index++)
            {
                GamepadState state;
                uint result = XInputGetState(index, out state);
                if (result == 1167) continue; // ERROR_DEVICE_NOT_CONNECTED
                if (result != 0) throw new Win32Exception((int)result);
                ControllerSample sample = new ControllerSample();
                sample.Slot = index + 1;
                sample.LeftStickPercent = StickPercent(state.Pad.LeftX, state.Pad.LeftY);
                sample.RightStickPercent = StickPercent(state.Pad.RightX, state.Pad.RightY);
                sample.LeftTriggerPercent = Math.Round(state.Pad.LeftTrigger / 255.0 * 100.0, 2);
                sample.RightTriggerPercent = Math.Round(state.Pad.RightTrigger / 255.0 * 100.0, 2);
                samples.Add(sample);
            }
            return samples.ToArray();
        }
    }
}
