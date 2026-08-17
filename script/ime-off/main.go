//go:build windows

// ime-off switches the IME associated with the foreground Windows terminal
// to direct input. It is built for Windows and invoked from Neovim in WSL.
package main

import (
	"os"
	"syscall"
)

const (
	wmIMEControl     = 0x0283
	imcSetOpenStatus = 6
)

var (
	getForegroundWindow = syscall.NewLazyDLL("user32.dll").NewProc("GetForegroundWindow")
	sendMessageW        = syscall.NewLazyDLL("user32.dll").NewProc("SendMessageW")
	immGetDefaultIMEWnd = syscall.NewLazyDLL("imm32.dll").NewProc("ImmGetDefaultIMEWnd")
)

func main() {
	hwnd, _, _ := getForegroundWindow.Call()
	if hwnd == 0 {
		os.Exit(1)
	}

	imeWnd, _, _ := immGetDefaultIMEWnd.Call(hwnd)
	if imeWnd == 0 {
		os.Exit(1)
	}

	sendMessageW.Call(imeWnd, wmIMEControl, imcSetOpenStatus, 0)
}
