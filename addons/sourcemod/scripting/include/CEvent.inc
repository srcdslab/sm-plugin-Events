#if defined _class_cevent_
    #endinput
#endif
#define _class_cevent_

#include <basic>

methodmap CEvent < Basic
{
    public CEvent(const char[] filename, const char[] name, const char[] description)
    {
        Basic myclass = new Basic();

        myclass.SetString("sFilename", filename);
        myclass.SetString("sName", name);
        myclass.SetString("sDescription", description);
        myclass.SetBool("bEnabled", false);

        return view_as<CEvent>(myclass);
    }

    public bool GetFilename(char[] buffer, int length) { return this.GetString("sFilename", buffer, length); }
    public void SetFilename(const char[] buffer) { this.SetString("sFilename", buffer); }

    public bool GetName(char[] buffer, int length) { return this.GetString("sName", buffer, length); }
    public void SetName(const char[] buffer) { this.SetString("sName", buffer); }

    public bool GetDescription(char[] buffer, int length) { return this.GetString("sDescription", buffer, length); }
    public void SetDescription(const char[] buffer) { this.SetString("sDescription", buffer); }

    property bool bEnabled {
        public get() { return this.GetBool("bEnabled"); }
        public set(bool enabled) { this.SetBool("bEnabled", enabled); }
    }

    public void Load(bool bLoad, bool bNotify)
    {
        if (this.bEnabled && bLoad)
            return;

        this.bEnabled = bLoad;

        char filename[256];
        this.GetFilename(filename, sizeof(filename));

        char cmd[512];
        Format(cmd, sizeof(cmd), "sm plugins %s %s", bLoad ? "load" : "unload", filename);

        ServerCommand(cmd);

        if (bNotify)
        {
            char name[64], description[512];
            this.GetName(name, sizeof(name));
            this.GetDescription(description, sizeof(description));

            if (bLoad)
                ServerCommand("sm_msay Event %s has started with the following rules:\\n%s\\nHave fun playing on our server ( ͡° ͜ʖ ͡°)", name, description);
            else
                ServerCommand("sm_msay Event %s has ended!\\nThank you for playing ( ͡° ͜ʖ ͡°)", name, description);
        }
    }
}