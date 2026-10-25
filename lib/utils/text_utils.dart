/// The first [n] characters of [s], or all of it when it is shorter.
/// (`s.substring(0, n)` throws on a short id.)
String firstChars(String s, int n) => s.length <= n ? s : s.substring(0, n);
