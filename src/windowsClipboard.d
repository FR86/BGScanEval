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
            //Clear any trash
		    EmptyClipboard();
            //make space for our string (plus zero terminator) and receive a handle to the new memory object
		    void* handle = GlobalAlloc(2, mystr.length + 1);
            //FIXME: bail if this returns null, optionally calling GetLastError to find out why
            //lock the piece of memory and get a pointer to its first byte
		    void* ptr = GlobalLock(handle);
            //FIXME: bail if null, like above
            import core.stdc.string : memcpy;
            import std.string : toStringz;
            //copy our string over to the allocated and locked piece of memory
            //this should work out because the implementation of toStringz just makes a copy and appends a zero
		    memcpy(ptr, toStringz(mystr), mystr.length + 1);
            
            //unlock the piece of memory
		    GlobalUnlock(handle);
            //FIXME: check if the result is zero and therefore, the operation succeeded.
            //Do NOT GlobalFree the memory, ownership is transferred to clipboard, which will free later!
            
            //Sets the clipboard data (text mode, 1) to our little memory block 
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
