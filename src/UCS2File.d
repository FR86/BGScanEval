module UCS2File;

import std.stdio : File;
import std.typecons : Flag, Yes, No;
alias KeepTerminator = Flag!"keepTerminator";
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
    this(File f, KeepTerminator kt = No.keepTerminator,
            wstring terminator = "\r\n"w)
    {
        impl = PImpl(f, kt, terminator);
    }

    @property bool empty()
    {
        return impl.refCountedPayload.empty;
    }

    @property wchar[] front()
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
        wchar[] line;
        wchar[] buffer;
        wstring terminator;
        KeepTerminator keepTerminator;

    public:
        this(File f, KeepTerminator kt, wstring terminator)
        {
            file = f;
            this.terminator = terminator;
            keepTerminator = kt;
            popFront();
        }

        // Range primitive implementations.
        @property bool empty()
        {
            return line is null;
        }

        @property wchar[] front()
        {
            return line;
        }

        void popFront()
        {
            import std.algorithm.searching : endsWith;
            assert(file.isOpen);
            line = buffer;
            file.readln(line, terminator);
            if (line.length > buffer.length)
            {
                //expands the buffer maybe?
                buffer = line;
            }
            import std.range.primitives : empty;
            if (line.empty)
            {
                file.detach();
                line = null;
            }
            else if (keepTerminator == No.keepTerminator
                    && line.endsWith(terminator))
            {
                line = line[0 .. line.length - terminator.length];
            }
        }
    }
}
