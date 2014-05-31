UNIT PostOnit;

INTERFACE

Uses CRT;

IMPLEMENTATION

Uses Overlay;

    BEGIN
    OvrSetBuf (70000);
    OvrInit ('POST.OVR');
    OvrInitEms;
    END.