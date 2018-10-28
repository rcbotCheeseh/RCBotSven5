class FileBuffer
{
    string data = "";
    int readPos = 0;

    array<string> g_HEXTOASCII;
    array<string> g_IntToAscii;

    FileBuffer()
    {
        g_HEXTOASCII.insertLast("0");
        g_HEXTOASCII.insertLast("1");
        g_HEXTOASCII.insertLast("2");
        g_HEXTOASCII.insertLast("3");
        g_HEXTOASCII.insertLast("4");
        g_HEXTOASCII.insertLast("5");
        g_HEXTOASCII.insertLast("6");
        g_HEXTOASCII.insertLast("7");
        g_HEXTOASCII.insertLast("8");
        g_HEXTOASCII.insertLast("9");
        g_HEXTOASCII.insertLast("A");
        g_HEXTOASCII.insertLast("B");
        g_HEXTOASCII.insertLast("C");
        g_HEXTOASCII.insertLast("D");
        g_HEXTOASCII.insertLast("E");
        g_HEXTOASCII.insertLast("F");
 
    }

    string getData()
    {
        return data;
    }

    FileBuffer(File &f)
    {        
        while ( !f.EOFReached() )
        {
            data += f.ReadCharacter();
        }

        f.Close();


        g_IntToAscii.insertLast(" ");
        g_IntToAscii.insertLast("!");
        g_IntToAscii.insertLast("\"");
        g_IntToAscii.insertLast("#");
        g_IntToAscii.insertLast("$");
        g_IntToAscii.insertLast("%");
        g_IntToAscii.insertLast("&");
        g_IntToAscii.insertLast("'");
        g_IntToAscii.insertLast("(");
        g_IntToAscii.insertLast(")");
        g_IntToAscii.insertLast("*");
        g_IntToAscii.insertLast("+");
        g_IntToAscii.insertLast(",");
        g_IntToAscii.insertLast("-");
        g_IntToAscii.insertLast(".");
        g_IntToAscii.insertLast("/");
        g_IntToAscii.insertLast("0");
        g_IntToAscii.insertLast("1");
        g_IntToAscii.insertLast("2");
        g_IntToAscii.insertLast("3");
        g_IntToAscii.insertLast("4");
        g_IntToAscii.insertLast("5");
        g_IntToAscii.insertLast("6");
        g_IntToAscii.insertLast("7");
        g_IntToAscii.insertLast("8");
        g_IntToAscii.insertLast("9");
        g_IntToAscii.insertLast(":");
        g_IntToAscii.insertLast(";");
        g_IntToAscii.insertLast("<");
        g_IntToAscii.insertLast("=");
        g_IntToAscii.insertLast(">");
        g_IntToAscii.insertLast("?");
        g_IntToAscii.insertLast("@");
        g_IntToAscii.insertLast("A");
        g_IntToAscii.insertLast("B");
        g_IntToAscii.insertLast("C");
        g_IntToAscii.insertLast("D");
        g_IntToAscii.insertLast("E");
        g_IntToAscii.insertLast("F");
        g_IntToAscii.insertLast("G");
        g_IntToAscii.insertLast("H");
        g_IntToAscii.insertLast("I");
        g_IntToAscii.insertLast("J");
        g_IntToAscii.insertLast("K");
        g_IntToAscii.insertLast("L");
        g_IntToAscii.insertLast("M");
        g_IntToAscii.insertLast("N");
        g_IntToAscii.insertLast("O");
        g_IntToAscii.insertLast("P");
        g_IntToAscii.insertLast("Q");
        g_IntToAscii.insertLast("R");
        g_IntToAscii.insertLast("S");
        g_IntToAscii.insertLast("T");
        g_IntToAscii.insertLast("U");
        g_IntToAscii.insertLast("V");
        g_IntToAscii.insertLast("W");
        g_IntToAscii.insertLast("X");
        g_IntToAscii.insertLast("Y");
        g_IntToAscii.insertLast("Z");
        g_IntToAscii.insertLast("[");
        g_IntToAscii.insertLast("'");
        g_IntToAscii.insertLast("]");
        g_IntToAscii.insertLast("^");
        g_IntToAscii.insertLast("_");
        g_IntToAscii.insertLast("`");
        g_IntToAscii.insertLast("a");
        g_IntToAscii.insertLast("b");
        g_IntToAscii.insertLast("c");
        g_IntToAscii.insertLast("d");
        g_IntToAscii.insertLast("e");
        g_IntToAscii.insertLast("f");
        g_IntToAscii.insertLast("g");
        g_IntToAscii.insertLast("h");
        g_IntToAscii.insertLast("i");
        g_IntToAscii.insertLast("j");
        g_IntToAscii.insertLast("k");
        g_IntToAscii.insertLast("l");
        g_IntToAscii.insertLast("m");
        g_IntToAscii.insertLast("n");
        g_IntToAscii.insertLast("o");
        g_IntToAscii.insertLast("p");
        g_IntToAscii.insertLast("q");
        g_IntToAscii.insertLast("r");
        g_IntToAscii.insertLast("s");
        g_IntToAscii.insertLast("t");
        g_IntToAscii.insertLast("u");
        g_IntToAscii.insertLast("v");
        g_IntToAscii.insertLast("w");
        g_IntToAscii.insertLast("x");
        g_IntToAscii.insertLast("y");
        g_IntToAscii.insertLast("z");
        g_IntToAscii.insertLast("{");
        g_IntToAscii.insertLast("|");
        g_IntToAscii.insertLast("}");
        g_IntToAscii.insertLast("~");               
    }


    uint8 FromAscii( uint8 n )
    {
        if (n >= 65)
            return (n - 55);

        return ( n - 48);
    }


    string ToAscii(uint8 n)
    {        
        return g_HEXTOASCII[n];
    }

    string CharFromAscii ( uint8 n )
    {
        string ret;
        uint8 ret_n = n;

        n -= 32;        

        if ( n > g_IntToAscii.length() )
            ret = "?";
        else
            ret = g_IntToAscii[n];

        
       // BotMessage("CharFromAScii("+ret_n+") => " + n + "," + ret + "(" + g_IntToAscii.length() + ")");

        return ret;
    }

    void writeByte(uint8 b)
    {        
        uint8 nib0 = ((b & 0xF0)>>4);
        uint8 nib1 = (b & 0x0F);

        string ascii = "" + ToAscii(nib0) + ToAscii(nib1);
        
       // BotMessage("writeByte("+b+") nib0 = " + nib0 + ", nib1 = " + nib1 + ", ASCII = '" + ascii + "'");

        data += ascii;
    }

    uint readByte( )
    {
        uint8 nib0 = FromAscii(data[readPos++]);
        uint8 nib1 = FromAscii(data[readPos++]);

        return ((nib1) + (nib0 << 4));
    }

    int ReadInt32()
    {
        int ret = 0;
        int shift = 0;

        for (int i = 0; i < 4; i++)
        {
            int read = readByte();

            read <<= shift;

            shift += 8;

            ret += read;            
        }

        return ret;
    }

    string ReadString(int len)
    {
        string ret = "";

        while (len-- > 0)
        {
            uint8 byte = readByte();

            if ( byte == 0 )
                break;            

            ret += CharFromAscii(byte);
        }

        while ( len -- > 0 )
        {
            readByte();
        }

        return ret;
    }

    float ReadFloat()
    {
        uint retInt = uint(ReadInt32());

        return fpFromIEEE(retInt);

    }

    void Write(int val)
    {        
        uint i = uint(val);

        for (int x = 0; x < 4; x++)
        {
            writeByte(uint8(i & 0xFF));
            i >>= 8;
        }
    }

    void Write(float f)
    {
        uint ret = fpToIEEE(f);

        Write(int(ret));     
    }

    void Write(string s, int len)
    {
        for ( int i = 0; i < len; i ++ )
        {
            if ( s[i] == 0 )
                break;
                
            writeByte(s[i]);
            len--;
        }

        while (len-- > 0)
        {
            writeByte(0);
        }
    }
}