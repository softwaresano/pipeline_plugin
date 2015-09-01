function trim(s)
{
    var l=0;
    var r=s.length -1;
    while(l < s.length && s[l] == ' ')
    {
        l++;
    }
    while(r > l && s[r] == ' ')
    {
        r-=1;
    }
    return s.substring(l, r+1);
}
