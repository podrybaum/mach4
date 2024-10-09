import os
import wx
from wx.lib.filebrowsebutton import DirBrowseButton

app = wx.App()

default_profile = [
    "[ControllerProfile-default]",
    "xc.LTH_Y_Val.deadzone=10.000000",
    "xc.RTH_X_Val.deadzone=10.000000",
    "xc.RTH_Y_Val.deadzone=10.000000",
    "xc.LTH_X_Val.deadzone=10.000000",
    "xc.jogIncrement=0.100000",
    "xc.logLevel=2.000000",
    "xc.xYReversed=false",
    "xc.frequency=4.000000",
    "xc.simpleJogMapped=false",
    "xc.profileName=default",
    "xc.shiftButton=LTR_Val",
    "xc.RTH_Y_Val.axis=2.000000",
    "xc.RTH_Y_Val.inverted=false",
    "xc.DPad_UP.Down.slot=xcJogUp",
    "xc.DPad_UP.Up.slot=xcJogStopY",
    "xc.DPad_DOWN.Down.slot=xcJogDown",
    "xc.DPad_DOWN.Up.slot=xcJogStopY",
    "xc.DPad_RIGHT.Down.slot=xcJogRight",
    "xc.DPad_RIGHT.Up.slot=xcJogStopX",
    "xc.DPad_LEFT.Down.slot=xcJogLeft",
    "xc.DPad_LEFT.Up.slot=xcJogStopX",
    "xc.DPad_UP.AltDown.slot=xcJogIncUp",
    "xc.DPad_DOWN.AltDown.slot=xcJogIncDown",
    "xc.DPad_RIGHT.AltDown.slot=xcJogIncRight",
    "xc.DPad_LEFT.AltDown.slot=xcJogIncLeft",
    "xc.Btn_B.Down.slot=E Stop Toggle",
    "xc.Btn_RS.Down.slot=Enable Toggle",
    "xc.Btn_X.Down.slot=XC Run Cycle Toggle",
    "xc.Btn_BACK.AltDown.slot=Home All"]

class InstallerFrame(wx.Frame):

    def __init__(self):
        super(InstallerFrame, self).__init__()

        self.pnl = wx.Panel(self)
        self.mach4_dir = ""

        welcome_label = wx.StaticText(self.pnl, label="Xbox Controller for Mach4 Installer")
        font = welcome_label.GetFont()
        font.PointSize += 10
        font = font.Bold()
        welcome_label.SetFont(font)

        self.sizer = wx.BoxSizer(wx.VERTICAL)
        self.sizer.Add(welcome_label, wx.SizerFlags().Border(wx.TOP|wx.LEFT, 25))
        self.pnl.SetSizer(self.sizer)

        self.CreateStatusBar()
        self.SetStatusText("Initializing Installer...")

        self.sizer.Layout()

    def initialize(self):
        if os.path.isdir("C:\\Mach4Hobby"):
            self.mach4_dir = "C:\\Mach4Hobby"
        
        else:
            def getDir(path):
                self.mach4_dir = path
            
            txt = wx.StaticText(self.pnl, label="We couldn't detect your Mach4 installation directory.\n\
                               Please provide the path to the root directory of your Mach4 installation.")
            dir_btn = wx.DirBrowseButton(self.pnl, startDirectory="C:\\", changeCallback=getDir)
            self.sizer.Add(txt, wx.SizerFlags().Border(wx.TOP|wx.LEFT, 15))
            self.sizer.Add(dir_btn)
            self.sizer.Layout()

    def OnExit(self, event):
        self.Close(True)

if __name__ == "__main__":
    app = wx.App()
    frm = InstallerFrame(None, title='XBC for Mach4 Installer')
    frm.Show()
    app.MainLoop()