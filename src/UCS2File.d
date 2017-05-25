module UCS2File;

import std.stdio : File;
import std.typecons : Flag, Yes, No;
alias KeepTerminator = Flag!"keepTerminator";

char[] readlnUCS2LE(File f, char terminator) {
    static char[1024*4] buffer;
    int i;
    while(f.rawRead(buffer[i .. i+2]) != null) {
        if (buffer[i] == terminator)
            break;
        i+=2;
    }

    return buffer[0 .. i];
}
struct ByUCS2Line
{
private:
    import std.typecons : RefCounted, RefCountedAutoInitialize;

    /* Ref-counting stops the source range's Impl
        * from getting out of sync after the range is copied, e.g.
        * when accessing range.front, then using std.range.take,
        * then accessing range.front again. */
    alias PImpl = RefCounted!(Impl, RefCountedAutoInitialize.no);
    PImpl impl;

public:
    this(File f, char terminator = '\n')
    {
        impl = PImpl(f, terminator);
    }

    @property bool empty()
    {
        return impl.refCountedPayload.empty;
    }

    @property char[] front()
    {
        return impl.refCountedPayload.front;
    }

    void popFront()
    {
        impl.refCountedPayload.popFront();
    }

private:
    struct Impl
    {
    private:
        File file;
        char[] line;
        char terminator;

    public:
        this(File f, char terminator)
        {
            file = f;
            this.terminator = terminator;
            popFront();
        }

        // Range primitive implementations.
        @property bool empty()
        {
            return line is null;
        }

        @property char[] front()
        {
            return line;
        }

        void popFront()
        {
            import std.algorithm.searching : endsWith;
            assert(file.isOpen);
            line = file.readlnUCS2LE(terminator);
            import std.range.primitives : empty;
            if (line.empty)
            {
                file.detach();
                line = null;
            }
            else if (line.endsWith(['\x0d', '\x00']))
            {
                line = line[0 .. line.length - 2];
            }
        }
    }
}
