int fb2Int(int x){
  var e = 0;
  if(x < 8) return x;
  while(x >= (8 << 4)){
    x = (x + 0xf) >> 4;
    e += 4;
  }
  while(x >= (8 << 1)){
    x = (x + 1) >> 1;
    e++;
  }
  return ((e + 1) << 3) | (x - 8);
}

int int2Fb(int x){
  if(x < 8) return x;
  return ((x & 7) + 8) << ((x >> 3) - 1);
}