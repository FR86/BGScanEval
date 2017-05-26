module windowsClipboard;

//found at and adapted from:
//http://forum.dlang.org/thread/j4jcp2$14q9$1@digitalmars.com
version(windows)
{
    extern(Windows)
    {
       bool OpenClipboard(void*);
       void* GetClipboardData(uint);
       void* SetClipboardData(uint, void*);
       bool EmptyClipboard();
       bool CloseClipboard();
       void* GlobalAlloc(uint, size_t);
       void* GlobalLock(void*);
       bool GlobalUnlock(void*);
    }


    /** This function will try and get text from the clipboard.
        Returns:
            null if no text could be copied, the clipboard text otherwise. 
    */
    string getTextClipboard()
    {
       if (OpenClipboard(null))
       {
	       scope(exit)
           {
               CloseClipboard();
           }
           //get clipboard data in text format
           auto cstr = cast(char*)GetClipboardData(1);
           import core.stdc.string : strlen;
           if(cstr)
           {
               //only return something if the result isn't null
               return cstr[0..strlen(cstr)].idup;
           }
	    }
	    return null;
    }

    /** This function will try and put text into the clipboard.
        Params:
            mystr = String to be pasted into clipboard.
        Returns:
            To be pasted string.
    */
    string setTextClipboard(string mystr)
    {
	    if (OpenClipboard(null))
        {
		    scope(exit)
            {
                CloseClipboard();
            }
		    EmptyClipboard();
		    void* handle = GlobalAlloc(2, mystr.length + 1);
		    void* ptr = GlobalLock(handle);
            import core.stdc.string : memcpy;
            import std.string : toStringz;
		    memcpy(ptr, toStringz(mystr), mystr.length + 1);
		    GlobalUnlock(handle);

		    SetClipboardData(1, handle);
	    }
	    return mystr;
    }

    unittest
    {
        string a = "Marvelous, truly fascinating! And even with umlauts: ä ü ö.";
        setTextClipboard(a);
        auto b = getTextClipboard();
        assert(b == a);
    }
}
