local StrToNumber=tonumber;local Byte=string.byte;local Char=string.char;local Sub=string.sub;local Subg=string.gsub;local Rep=string.rep;local Concat=table.concat;local Insert=table.insert;local LDExp=math.ldexp;local GetFEnv=getfenv or function()return _ENV;end ;local Setmetatable=setmetatable;local PCall=pcall;local Select=select;local Unpack=unpack or table.unpack ;local ToNumber=tonumber;local function VMCall(ByteString,vmenv,...)local DIP=1;local repeatNext;ByteString=Subg(Sub(ByteString,5),"..",function(byte)if (Byte(byte,2)==79) then repeatNext=StrToNumber(Sub(byte,1,1));return "";else local a=Char(StrToNumber(byte,16));if repeatNext then local b=Rep(a,repeatNext);repeatNext=nil;return b;else return a;end end end);local function gBit(Bit,Start,End)if End then local Res=(Bit/(2^(Start-1)))%(2^(((End-1) -(Start-1)) + 1)) ;return Res-(Res%1) ;else local Plc=2^(Start-1) ;return (((Bit%(Plc + Plc))>=Plc) and 1) or 0 ;end end local function gBits8()local a=Byte(ByteString,DIP,DIP);DIP=DIP + 1 ;return a;end local function gBits16()local a,b=Byte(ByteString,DIP,DIP + 2 );DIP=DIP + 2 ;return (b * 256) + a ;end local function gBits32()local a,b,c,d=Byte(ByteString,DIP,DIP + 3 );DIP=DIP + 4 ;return (d * 16777216) + (c * 65536) + (b * 256) + a ;end local function gFloat()local Left=gBits32();local Right=gBits32();local IsNormal=1;local Mantissa=(gBit(Right,1,20) * (2^32)) + Left ;local Exponent=gBit(Right,21,31);local Sign=((gBit(Right,32)==1) and  -1) or 1 ;if (Exponent==0) then if (Mantissa==0) then return Sign * 0 ;else Exponent=1;IsNormal=0;end elseif (Exponent==2047) then return ((Mantissa==0) and (Sign * (1/0))) or (Sign * NaN) ;end return LDExp(Sign,Exponent-1023 ) * (IsNormal + (Mantissa/(2^52))) ;end local function gString(Len)local Str;if  not Len then Len=gBits32();if (Len==0) then return "";end end Str=Sub(ByteString,DIP,(DIP + Len) -1 );DIP=DIP + Len ;local FStr={};for Idx=1, #Str do FStr[Idx]=Char(Byte(Sub(Str,Idx,Idx)));end return Concat(FStr);end local gInt=gBits32;local function _R(...)return {...},Select("#",...);end local function Deserialize()local Instrs={};local Functions={};local Lines={};local Chunk={Instrs,Functions,nil,Lines};local ConstCount=gBits32();local Consts={};for Idx=1,ConstCount do local Type=gBits8();local Cons;if (Type==1) then Cons=gBits8()~=0 ;elseif (Type==2) then Cons=gFloat();elseif (Type==3) then Cons=gString();end Consts[Idx]=Cons;end Chunk[3]=gBits8();for Idx=1,gBits32() do local Descriptor=gBits8();if (gBit(Descriptor,1,1)==0) then local Type=gBit(Descriptor,2,3);local Mask=gBit(Descriptor,4,6);local Inst={gBits16(),gBits16(),nil,nil};if (Type==0) then Inst[3]=gBits16();Inst[4]=gBits16();elseif (Type==1) then Inst[3]=gBits32();elseif (Type==2) then Inst[3]=gBits32() -(2^16) ;elseif (Type==3) then Inst[3]=gBits32() -(2^16) ;Inst[4]=gBits16();end if (gBit(Mask,1,1)==1) then Inst[2]=Consts[Inst[2]];end if (gBit(Mask,2,2)==1) then Inst[3]=Consts[Inst[3]];end if (gBit(Mask,3,3)==1) then Inst[4]=Consts[Inst[4]];end Instrs[Idx]=Inst;end end for Idx=1,gBits32() do Functions[Idx-1 ]=Deserialize();end for Idx=1,gBits32() do Lines[Idx]=gBits32();end return Chunk;end local function Wrap(Chunk,Upvalues,Env)local Instr=Chunk[1];local Proto=Chunk[2];local Params=Chunk[3];return function(...)local VIP=1;local Top= -1;local Args={...};local PCount=Select("#",...) -1 ;local function Loop()local Instr=Instr;local Proto=Proto;local Params=Params;local _R=_R;local Vararg={};local Lupvals={};local Stk={};for Idx=0,PCount do if (Idx>=Params) then Vararg[Idx-Params ]=Args[Idx + 1 ];else Stk[Idx]=Args[Idx + 1 ];end end local Varargsz=(PCount-Params) + 1 ;local Inst;local Enum;while true do Inst=Instr[VIP];Enum=Inst[1];if (Enum<=21) then if (Enum<=10) then if (Enum<=4) then if (Enum<=1) then if (Enum==0) then local A=Inst[2];Stk[A]=Stk[A](Stk[A + 1 ]);else Stk[Inst[2]][Inst[3]]=Stk[Inst[4]];end elseif (Enum<=2) then local A=Inst[2];local Results,Limit=_R(Stk[A](Stk[A + 1 ]));Top=(Limit + A) -1 ;local Edx=0;for Idx=A,Top do Edx=Edx + 1 ;Stk[Idx]=Results[Edx];end elseif (Enum==3) then Stk[Inst[2]]= -Stk[Inst[3]];else local A=Inst[2];local Results,Limit=_R(Stk[A](Unpack(Stk,A + 1 ,Top)));Top=(Limit + A) -1 ;local Edx=0;for Idx=A,Top do Edx=Edx + 1 ;Stk[Idx]=Results[Edx];end end elseif (Enum<=7) then if (Enum<=5) then local A=Inst[2];Stk[A](Unpack(Stk,A + 1 ,Inst[3]));elseif (Enum>6) then do return;end else Env[Inst[3]]=Stk[Inst[2]];end elseif (Enum<=8) then local A=Inst[2];Stk[A]=Stk[A]();elseif (Enum>9) then local A=Inst[2];Stk[A](Stk[A + 1 ]);else Stk[Inst[2]]=Stk[Inst[3]] * Stk[Inst[4]] ;end elseif (Enum<=15) then if (Enum<=12) then if (Enum>11) then local A=Inst[2];Stk[A]=Stk[A](Unpack(Stk,A + 1 ,Top));else Stk[Inst[2]]=Stk[Inst[3]] * Inst[4] ;end elseif (Enum<=13) then Stk[Inst[2]]=Inst[3]~=0 ;elseif (Enum>14) then local A=Inst[2];local C=Inst[4];local CB=A + 2 ;local Result={Stk[A](Stk[A + 1 ],Stk[CB])};for Idx=1,C do Stk[CB + Idx ]=Result[Idx];end local R=Result[1];if R then Stk[CB]=R;VIP=Inst[3];else VIP=VIP + 1 ;end elseif (Stk[Inst[2]]<Stk[Inst[4]]) then VIP=VIP + 1 ;else VIP=Inst[3];end elseif (Enum<=18) then if (Enum<=16) then Stk[Inst[2]]={};elseif (Enum>17) then if  not Stk[Inst[2]] then VIP=VIP + 1 ;else VIP=Inst[3];end else Stk[Inst[2]]=Wrap(Proto[Inst[3]],nil,Env);end elseif (Enum<=19) then Stk[Inst[2]][Inst[3]]=Inst[4];elseif (Enum>20) then for Idx=Inst[2],Inst[3] do Stk[Idx]=nil;end else local A=Inst[2];local Results,Limit=_R(Stk[A](Unpack(Stk,A + 1 ,Inst[3])));Top=(Limit + A) -1 ;local Edx=0;for Idx=A,Top do Edx=Edx + 1 ;Stk[Idx]=Results[Edx];end end elseif (Enum<=32) then if (Enum<=26) then if (Enum<=23) then if (Enum==22) then Stk[Inst[2]]=Stk[Inst[3]] -Stk[Inst[4]] ;else local B=Inst[3];local K=Stk[B];for Idx=B + 1 ,Inst[4] do K=K   .. Stk[Idx] ;end Stk[Inst[2]]=K;end elseif (Enum<=24) then Stk[Inst[2]]=Inst[3];elseif (Enum==25) then Stk[Inst[2]]=Upvalues[Inst[3]];else local A=Inst[2];local B=Stk[Inst[3]];Stk[A + 1 ]=B;Stk[A]=B[Inst[4]];end elseif (Enum<=29) then if (Enum<=27) then do return Stk[Inst[2]];end elseif (Enum>28) then if (Stk[Inst[2]]~=Inst[4]) then VIP=VIP + 1 ;else VIP=Inst[3];end elseif Stk[Inst[2]] then VIP=VIP + 1 ;else VIP=Inst[3];end elseif (Enum<=30) then Stk[Inst[2]]=Stk[Inst[3]][Stk[Inst[4]]];elseif (Enum>31) then Stk[Inst[2]]=Env[Inst[3]];elseif (Stk[Inst[2]]==Stk[Inst[4]]) then VIP=VIP + 1 ;else VIP=Inst[3];end elseif (Enum<=38) then if (Enum<=35) then if (Enum<=33) then local A=Inst[2];local Results={Stk[A](Unpack(Stk,A + 1 ,Top))};local Edx=0;for Idx=A,Inst[4] do Edx=Edx + 1 ;Stk[Idx]=Results[Edx];end elseif (Enum==34) then if (Stk[Inst[2]]~=Stk[Inst[4]]) then VIP=VIP + 1 ;else VIP=Inst[3];end else Stk[Inst[2]]=Stk[Inst[3]];end elseif (Enum<=36) then if (Stk[Inst[2]]==Inst[4]) then VIP=VIP + 1 ;else VIP=Inst[3];end elseif (Enum==37) then VIP=Inst[3];else local A=Inst[2];do return Unpack(Stk,A,A + Inst[3] );end end elseif (Enum<=41) then if (Enum<=39) then Stk[Inst[2]]=Stk[Inst[3]] + Stk[Inst[4]] ;elseif (Enum==40) then Upvalues[Inst[3]]=Stk[Inst[2]];else Stk[Inst[2]]=Stk[Inst[3]][Inst[4]];end elseif (Enum<=42) then local A=Inst[2];Stk[A]=Stk[A](Unpack(Stk,A + 1 ,Inst[3]));elseif (Enum>43) then local NewProto=Proto[Inst[3]];local NewUvals;local Indexes={};NewUvals=Setmetatable({},{__index=function(_,Key)local Val=Indexes[Key];return Val[1][Val[2]];end,__newindex=function(_,Key,Value)local Val=Indexes[Key];Val[1][Val[2]]=Value;end});for Idx=1,Inst[4] do VIP=VIP + 1 ;local Mvm=Instr[VIP];if (Mvm[1]==35) then Indexes[Idx-1 ]={Stk,Mvm[3]};else Indexes[Idx-1 ]={Upvalues,Mvm[3]};end Lupvals[ #Lupvals + 1 ]=Indexes;end Stk[Inst[2]]=Wrap(NewProto,NewUvals,Env);else Stk[Inst[2]]();end VIP=VIP + 1 ;end end A,B=_R(PCall(Loop));if  not A[1] then local line=Chunk[4][VIP] or "?" ;error("Script error at ["   .. line   .. "]:"   .. A[2] );else return Unpack(A,2,B);end end;end return Wrap(Deserialize(),{},vmenv)(...);end VMCall("LOL!413O00030A3O006C6F6164737472696E6703043O0067616D6503073O00482O747047657403483O00682O7470733A2O2F7261772E67697468756275736572636F6E74656E742E636F6D2F626C2O6F6462612O6C2F2D6261636B2D7570732D666F722D6C6962732F6D61696E2F4O61030C3O0043726561746557696E646F7703043O0068617465030F3O0068692O6C6D7572646572207577752003073O00612O645061676503093O002O412F446573796E63026O00F03F026O00184003083O00612O644C6162656C03103O00416E74692D41696D2F446573796E637303093O00612O64546F2O676C652O033O003O3F030B3O00556E64657267726F756E642O033O00536B7903083O004D2O6F6E77616C6B03073O00426C6174616E7403023O005F4703063O00656E61626C65010003053O00636F6C6F7203063O00436F6C6F723303073O0066726F6D524742025O00E06F4003063O00747261636572034O0003083O00757365727669657703063O006D6574686F6403083O004D6F757365506F73030A3O0041696D2056696577657203133O00566965772041696D206F6620506C6179657273030A3O00612O6454657874426F78030A3O00547261636572204B657903093O00496E707574204B657903083O0056696577204B6579030A3O0047657453657276696365030A3O0052756E5365727669636503073O00506C6179657273030B3O004C6F63616C506C6179657203083O004765744D6F75736503063O0067657467756E030A3O006765745F636C6F73657403073O004B6579446F776E03073O00436F2O6E65637403083O00496E7374616E63652O033O006E657703043O004265616D03083O005365676D656E747303063O00576964746830029A5O99C93F03063O0057696474683103053O00436F6C6F72030D3O00436F6C6F7253657175656E6365030A3O004661636543616D6572612O01030A3O00412O746163686D656E74030B3O00412O746163686D656E7430030B3O00412O746163686D656E743103063O00506172656E7403093O00776F726B737061636503073O0054652O7261696E03043O007461736B03053O00737061776E00913O0012203O00013O001220000100023O00201A000100010003001218000300044O0014000100034O000C5O00022O00083O0001000200201A00013O0005001218000300063O001218000400074O002A00010004000200201A000200010008001218000400093O0012180005000A4O000D000600013O0012180007000B4O002A00020007000200201A00030002000C0012180005000D4O000500030005000100201A00030002000E0012180005000F3O00021100066O000500030006000100201A00030002000E001218000500103O000211000600014O000500030006000100201A00030002000E001218000500113O000211000600024O000500030006000100201A00030002000E001218000500123O000211000600034O000500030006000100201A00030002000E001218000500133O000211000600044O0005000300060001001220000300143O003013000300150016001220000300143O001220000400183O0020290004000400190012180005001A3O0012180006001A3O0012180007001A4O002A000400070002001001000300170004001220000300143O0030130003001B001C001220000300143O0030130003001D001C001220000300143O0030130003001E001F00201A000300010008001218000500203O0012180006000A4O000D000700013O0012180008000B4O002A00030008000200201A00040003000C001218000600214O000500040006000100201A000400030022001218000600233O001218000700243O000211000800054O000500040008000100201A000400030022001218000600253O001218000700243O000211000800064O0005000400080001001220000400023O00201A000400040026001218000600274O002A000400060002001220000500023O00202900050005002800202900050005002900201A00060005002A4O0006000200022O0015000700073O00062C00080007000100012O00233O00073O0012060008002B3O00062C00080008000100022O00233O00054O00233O00063O0012060008002C3O00202900080006002D00201A00080008002E000211000A00094O00050008000A000100202900080006002D00201A00080008002E00062C000A000A000100012O00233O00074O00050008000A00010012200008002F3O002029000800080030001218000900316O00080002000200301300080032000A003013000800330034003013000800350034001220000900373O002029000900090030001220000A00143O002029000A000A00174O0009000200020010010008003600090030130008003800390012200009002F3O002029000900090030001218000A003A6O000900020002001220000A002F3O002029000A000A0030001218000B003A6O000A000200020010010008003B00090010010008003C000A001220000B003E3O002029000B000B003F0010010008003D000B001220000B003E3O002029000B000B003F0010010009003D000B001220000B003E3O002029000B000B003F001001000A003D000B001220000B00403O002029000B000B004100062C000C000B000100062O00233O00044O00233O00054O00233O00084O00233O00074O00233O00094O00233O000A4O000A000B000200012O00073O00013O000C3O00113O00010003043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O005465787403083O003O3F204F2O662103073O0067657467656E762O033O00676F6403073O003O3F204F6E212O01030A3O0047657453657276696365030A3O0052756E5365727669636503093O0068656172746265617403073O00436F2O6E65637401223O0026243O000E000100010004253O000E0001001220000100023O00202900010001000300201A000100010004001218000300054O001000043O00020030130004000600070030130004000800092O00050001000400010012200001000A4O00080001000100020030130001000B00010004253O00210001001220000100023O00202900010001000300201A000100010004001218000300054O001000043O000200301300040006000700301300040008000C2O00050001000400010012200001000A4O00080001000100020030130001000B000D001220000100023O00201A00010001000E0012180003000F4O002A00010003000200202900010001001000201A00010001001100021100036O00050001000300012O00073O00013O00013O00133O0003073O0067657467656E762O033O00676F642O0103043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403083O0056656C6F6369747903073O00566563746F72332O033O006E6577025O00804640026O003440026O004940020080E03779C34143030A3O0047657453657276696365030A3O0052756E53657276696365030D3O0052656E6465725374652O70656403043O005761697400263O0012203O00014O00083O000100020020295O00020026243O0025000100030004253O002500010012203O00043O0020295O00050020295O00060020295O00070020295O00080020295O0009001220000100043O0020290001000100050020290001000100060020290001000100070020290001000100080012200002000A3O00202900020002000B0012180003000C3O0012180004000D3O0012180005000E4O002A00020005000200200B00020002000F001001000100090002001220000100043O00201A000100010010001218000300114O002A00010003000200202900010001001200201A0001000100132O000A000100020001001220000100043O002029000100010005002029000100010006002029000100010007002029000100010008001001000100094O00073O00017O00263O000D3O000D3O000D3O000D3O000D3O000E3O000E3O000E3O000E3O000E3O000E3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O000F3O00103O00103O00103O00103O00103O00103O00103O00113O00113O00113O00113O00113O00113O00133O00223O00063O00063O00073O00073O00073O00073O00073O00073O00073O00073O00083O00083O00083O00083O000A3O000A3O000A3O000A3O000A3O000A3O000A3O000A3O000B3O000B3O000B3O000C3O000C3O000C3O000C3O000C3O000C3O00133O000C3O00153O00143O0003053O007072696E74010003043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O005465787403103O00556E64657267726F756E64204F2O662103073O0067657467656E7603043O00756E6467030F3O00556E64657267726F756E64204F6E212O0103113O00556E64657267726F756E64416D6F756E74025O00C88940030A3O0047657453657276696365030A3O0052756E5365727669636503093O0068656172746265617403073O00436F2O6E65637401283O001220000100014O002300026O000A0001000200010026243O0011000100020004253O00110001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O000200301300040007000800301300040009000A2O00050001000400010012200001000B4O00080001000100020030130001000C00020004253O00270001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O000200301300040007000800301300040009000D2O00050001000400010012200001000B4O00080001000100020030130001000C000E0012200001000B4O00080001000100020030130001000F0010001220000100033O00201A000100010011001218000300124O002A00010003000200202900010001001300201A00010001001400021100036O00050001000300012O00073O00013O00013O00113O0003073O0067657467656E7603043O00756E6467010003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403083O0056656C6F6369747903073O00566563746F72332O033O006E6577028O0003113O00556E64657267726F756E64416D6F756E74030A3O0047657453657276696365030A3O0052756E53657276696365030D3O0052656E6465725374652O70656403043O005761697400283O0012203O00014O00083O000100020020295O000200261D3O0027000100030004253O002700010012203O00043O0020295O00050020295O00060020295O00070020295O00080020295O0009001220000100043O0020290001000100050020290001000100060020290001000100070020290001000100080012200002000A3O00202900020002000B0012180003000C3O001220000400014O000800040001000200202900040004000D2O0003000400043O0012180005000C4O002A000200050002001001000100090002001220000100043O00201A00010001000E0012180003000F4O002A00010003000200202900010001001000201A0001000100112O000A000100020001001220000100043O002029000100010005002029000100010006002029000100010007002029000100010008001001000100094O00073O00017O00283O00203O00203O00203O00203O00203O00213O00213O00213O00213O00213O00213O00223O00223O00223O00223O00223O00223O00223O00223O00223O00223O00223O00223O00223O00223O00223O00233O00233O00233O00233O00233O00233O00233O00243O00243O00243O00243O00243O00243O00263O00283O00173O00173O00173O00183O00183O00193O00193O00193O00193O00193O00193O00193O00193O001A3O001A3O001A3O001A3O001C3O001C3O001C3O001C3O001C3O001C3O001C3O001C3O001D3O001D3O001D3O001E3O001E3O001E3O001F3O001F3O001F3O001F3O001F3O001F3O00263O001F3O00283O00143O0003053O007072696E74010003043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O005465787403083O00536B79204F2O662103073O0067657467656E762O033O00536B7903073O00536B79204F6E212O0103093O00536B79416D6F756E74025O00C88940030A3O0047657453657276696365030A3O0052756E5365727669636503093O0068656172746265617403073O00436F2O6E65637401283O001220000100014O002300026O000A0001000200010026243O0011000100020004253O00110001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O000200301300040007000800301300040009000A2O00050001000400010012200001000B4O00080001000100020030130001000C00020004253O00270001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O000200301300040007000800301300040009000D2O00050001000400010012200001000B4O00080001000100020030130001000C000E0012200001000B4O00080001000100020030130001000F0010001220000100033O00201A000100010011001218000300124O002A00010003000200202900010001001300201A00010001001400021100036O00050001000300012O00073O00013O00013O00113O0003073O0067657467656E762O033O00536B79010003043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403083O0056656C6F6369747903073O00566563746F72332O033O006E6577028O0003093O00536B79416D6F756E74030A3O0047657453657276696365030A3O0052756E53657276696365030D3O0052656E6465725374652O70656403043O005761697400273O0012203O00014O00083O000100020020295O000200261D3O0026000100030004253O002600010012203O00043O0020295O00050020295O00060020295O00070020295O00080020295O0009001220000100043O0020290001000100050020290001000100060020290001000100070020290001000100080012200002000A3O00202900020002000B0012180003000C3O001220000400014O000800040001000200202900040004000D0012180005000C4O002A000200050002001001000100090002001220000100043O00201A00010001000E0012180003000F4O002A00010003000200202900010001001000201A0001000100112O000A000100020001001220000100043O002029000100010005002029000100010006002029000100010007002029000100010008001001000100094O00073O00017O00273O00333O00333O00333O00333O00333O00343O00343O00343O00343O00343O00343O00353O00353O00353O00353O00353O00353O00353O00353O00353O00353O00353O00353O00353O00353O00363O00363O00363O00363O00363O00363O00363O00373O00373O00373O00373O00373O00373O00393O00283O002A3O002A3O002A3O002B3O002B3O002C3O002C3O002C3O002C3O002C3O002C3O002C3O002C3O002D3O002D3O002D3O002D3O002F3O002F3O002F3O002F3O002F3O002F3O002F3O002F3O00303O00303O00303O00313O00313O00313O00323O00323O00323O00323O00323O00323O00393O00323O003B3O001D3O0003053O007072696E74010003043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O0054657874030D3O004D2O6F6E77616C6B204F2O662103073O0067657467656E7603113O00636672616D6573702O6564746F2O676C65030A3O0073702O656476616C7565028O0003083O00616E74696C6F636B030D3O00616E74696C6F636B73702O6564030C3O004D2O6F6E77616C6B204F6E212O01027B14AE47E17AEC3F026O00E03F03043O006D61746803063O0072616E646F6D026O003040026O004940026O004E40030A3O0047657453657276696365030A3O0052756E5365727669636503093O0048656172746265617403073O00436F2O6E656374013D3O001220000100014O002300026O000A0001000200010026243O001A000100020004253O001A0001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O000200301300040007000800301300040009000A2O00050001000400010012200001000B4O00080001000100020030130001000C00020012200001000B4O00080001000100020030130001000D000E0012200001000B4O00080001000100020030130001000F00020012200001000B4O000800010001000200301300010010000E0004253O003C0001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O00020030130004000700080030130004000900112O00050001000400010012200001000B4O00080001000100020030130001000C00120012200001000B4O00080001000100020030130001000D00130012200001000B4O00080001000100020030130001000F00120012200001000B4O0008000100010002003013000100100014001220000100153O002029000100010016001218000200173O001218000300184O002A000100030002001218000200193O001220000300033O00201A00030003001A0012180005001B4O002A00030005000200202900030003001C00201A00030003001D00021100056O00050003000500012O00073O00013O00013O000B3O0003073O0067657467656E7603083O00616E74696C6F636B03043O0067616D6503073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403063O00434672616D6503083O0048756D616E6F6964030D3O004D6F7665446972656374696F6E030D3O00616E74696C6F636B73702O6564001E3O0012203O00014O00083O000100020020295O000200061C3O001D00013O0004253O001D00010012203O00033O0020295O00040020295O00050020295O00060020295O0007001220000100033O002029000100010004002029000100010005002029000100010006002029000100010007002029000100010008001220000200033O00202900020002000400202900020002000500202900020002000600202900020002000900202900020002000A2O0003000200023O001220000300014O000800030001000200202900030003000B2O00090002000200032O00270001000100020010013O000800012O00073O00017O001E3O004D3O004D3O004D3O004D3O004D3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O004E3O00503O003D3O003D3O003D3O003D3O003E3O003E3O003F3O003F3O003F3O003F3O003F3O003F3O003F3O003F3O00403O00403O00403O00413O00413O00413O00423O00423O00423O00433O00433O00433O00433O00453O00453O00453O00453O00453O00453O00453O00453O00463O00463O00463O00473O00473O00473O00483O00483O00483O00493O00493O00493O004A3O004A3O004A3O004A3O004A3O004B3O004C3O004C3O004C3O004C3O004C3O004C3O00503O004C3O00523O00233O0003053O007072696E74010003043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O0054657874030C3O00426C6174616E74204F2O662103073O0067657467656E76030A3O0053656D69526167652O4103093O00426C6174616E742O41030B3O00426C6174616E74204F6E212O0103073O00506C6179657273030B3O004C6F63616C506C6179657203093O0043686172616374657203103O0048756D616E6F6964522O6F745061727403083O00506F736974696F6E03043O007461736B03043O007761697403063O00434672616D652O033O006E657703073O00566563746F723303043O006D61746803063O0072616E646F6D026O002EC0026O002E4003063O00416E676C65732O033O00726164025O008066C0025O00806640026O0014C0026O00F03F01AD3O001220000100014O002300026O000A0001000200010026243O0014000100020004253O00140001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O000200301300040007000800301300040009000A2O00050001000400010012200001000B4O00080001000100020030130001000C00020012200001000B4O00080001000100020030130001000D00020004253O00AC0001001220000100033O00202900010001000400201A000100010005001218000300064O001000043O000200301300040007000800301300040009000E2O00050001000400010012200001000B4O00080001000100020030130001000C00020012200001000B4O00080001000100020030130001000D000F001220000100033O0020290001000100100020290001000100110020290001000100120020290001000100130020290001000100140012200002000B4O000800020001000200202900020002000D0026240002006A0001000F0004253O006A0001001220000200153O0020290002000200162O002B000200010001001220000200033O002029000200020010002029000200020011002029000200020012002029000200020013001220000300173O0020290003000300182O0023000400016O000300020002001220000400193O0020290004000400180012200005001A3O00202900050005001B0012180006001C3O0012180007001D4O002A0005000700020012200006001A3O00202900060006001B0012180007001C3O0012180008001D4O002A0006000800020012200007001A3O00202900070007001B0012180008001C3O0012180009001D4O0014000700094O000C00043O00022O0027000300030004001220000400173O00202900040004001E0012200005001A3O00202900050005001F0012200006001A3O00202900060006001B001218000700203O001218000800214O0014000600084O000C00053O00020012200006001A3O00202900060006001F0012200007001A3O00202900070007001B001218000800203O001218000900214O0014000700094O000C00063O00020012200007001A3O00202900070007001F0012200008001A3O00202900080008001B001218000900203O001218000A00214O00140008000A4O000400076O000C00043O00022O00090003000300040010010002001700030004253O002800010012200002000B4O000800020001000200202900020002000C002624000200AC0001000F0004253O00AC0001001220000200153O0020290002000200162O002B000200010001001220000200033O002029000200020010002029000200020011002029000200020012002029000200020013001220000300173O0020290003000300182O0023000400016O000300020002001220000400193O0020290004000400180012200005001A3O00202900050005001B001218000600223O001218000700234O002A0005000700020012200006001A3O00202900060006001B001218000700223O001218000800234O002A0006000800020012200007001A3O00202900070007001B001218000800223O001218000900234O0014000700094O000C00043O00022O0027000300030004001220000400173O00202900040004001E0012200005001A3O00202900050005001F0012200006001A3O00202900060006001B001218000700223O001218000800234O0014000600084O000C00053O00020012200006001A3O00202900060006001F0012200007001A3O00202900070007001B001218000800223O001218000900234O0014000700094O000C00063O00020012200007001A3O00202900070007001F0012200008001A3O00202900080008001B001218000900223O001218000A00234O00140008000A4O000400076O000C00043O00022O00090003000300040010010002001700030004253O006A00012O00073O00017O00AD3O00543O00543O00543O00553O00553O00563O00563O00563O00563O00563O00563O00563O00563O00573O00573O00573O00583O00583O00583O00583O005A3O005A3O005A3O005A3O005A3O005A3O005A3O005A3O005B3O005B3O005B3O005C3O005C3O005C3O005D3O005D3O005D3O005D3O005D3O005D3O005E3O005E3O005E3O005E3O005E3O005F3O005F3O005F3O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00603O00623O00623O00623O00623O00623O00633O00633O00633O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00643O00673O000A3O0003043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O005465787403173O004368616E67656420747261636572206B657920746F3A2003023O005F4703063O00747261636572010E3O001220000100013O00202900010001000200201A000100010003001218000300044O001000043O0002003013000400050006001218000500084O002300066O00170005000500060010010004000700052O0005000100040001001220000100093O0010010001000A4O00073O00017O000E3O00703O00703O00703O00703O00703O00703O00703O00703O00703O00703O00703O00713O00713O00723O000A3O0003043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O005465787403153O004368616E6765642076696577206B657920746F3A2003023O005F4703083O007573657276696577010E3O001220000100013O00202900010001000200201A000100010003001218000300044O001000043O0002003013000400050006001218000500084O002300066O00170005000500060010010004000700052O0005000100040001001220000100093O0010010001000A4O00073O00017O000E3O00743O00743O00743O00743O00743O00743O00743O00743O00743O00743O00743O00753O00753O00763O00063O0003053O00706169727303093O00436861726163746572030B3O004765744368696C6472656E030E3O0046696E6446697273744368696C6403073O0044656661756C7403063O0048616E646C6500173O0012203O00014O001900015O00202900010001000200201A0001000100032O0002000100024O00215O00020004253O0014000100061C0004001400013O0004253O0014000100201A000500040004001218000700054O002A00050007000200061200050013000100010004253O0013000100201A000500040004001218000700064O002A00050007000200061C0005001400013O0004253O001400012O001B000400023O00060F3O0007000100020004253O000700012O00073O00017O00173O007C3O007C3O007C3O007C3O007C3O007C3O007C3O007D3O007D3O007D3O007D3O007D3O007D3O007D3O007D3O007D3O007D3O007D3O007D3O007E3O007C3O007F3O00813O00143O0003043O006D61746803043O006875676503053O00706169727303043O0067616D6503073O00506C6179657273030A3O00476574506C617965727303093O00436861726163746572030E3O0046696E6446697273744368696C6403043O004865616403103O0048756D616E6F6964522O6F745061727403093O00576F726B7370616365030D3O0043752O72656E7443616D65726103143O00576F726C64546F56696577706F7274506F696E74030B3O005072696D6172795061727403083O00506F736974696F6E03073O00566563746F72322O033O006E657703013O005803013O005903093O004D61676E6974756465003A3O0012203O00013O0020295O00022O0015000100013O001220000200033O001220000300043O00202900030003000500201A0003000300062O0002000300044O002100023O00040004253O003600012O001900075O00062200060036000100070004253O0036000100202900070006000700061C0007003600013O0004253O0036000100202900070006000700201A000700070008001218000900094O002A00070009000200061C0007003600013O0004253O0036000100202900070006000700201A0007000700080012180009000A4O002A00070009000200061C0007003600013O0004253O00360001001220000700043O00202900070007000B00202900070007000C00201A00070007000D00202900090006000700202900090009000E00202900090009000F2O002A000700090002001220000800103O0020290008000800112O0019000900013O0020290009000900122O0019000A00013O002029000A000A00132O002A0008000A0002001220000900103O002029000900090011002029000A00070012002029000B000700132O002A0009000B00022O001600080008000900202900080008001400060E0008003600013O0004253O003600012O0023000100064O00233O00083O00060F0002000A000100020004253O000A00012O001B000100024O00073O00017O003A3O00833O00833O00843O00853O00853O00853O00853O00853O00853O00853O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00863O00873O00873O00873O00873O00873O00873O00873O00873O00883O00883O00883O00883O00883O00883O00883O00883O00883O00883O00883O00883O00883O00883O00893O00893O008A3O008B3O00853O008D3O008F3O00903O000E3O0003023O005F4703063O0074726163657203063O00656E61626C6501002O0103043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O0054657874030A3O00547261636572204F6E21030B3O00547261636572204F2O662101223O001220000100013O00202900010001000200061F3O0021000100010004253O00210001001220000100013O00202900010001000300262400010013000100040004253O00130001001220000100013O003013000100030005001220000100063O00202900010001000700201A000100010008001218000300094O001000043O00020030130004000A000B0030130004000C000D2O00050001000400010004253O00210001001220000100013O00202900010001000300262400010021000100050004253O00210001001220000100013O003013000100030004001220000100063O00202900010001000700201A000100010008001218000300094O001000043O00020030130004000A000B0030130004000C000E2O00050001000400012O00073O00017O00223O00923O00923O00923O00923O00933O00933O00933O00933O00943O00943O00953O00953O00953O00953O00953O00953O00953O00953O00953O00963O00963O00963O00963O00973O00973O00983O00983O00983O00983O00983O00983O00983O00983O009B3O000D3O0003023O005F4703083O007573657276696577030A3O006765745F636C6F73657403043O0067616D65030A3O005374617274657247756903073O00536574436F726503103O0053656E644E6F74696669636174696F6E03053O005469746C6503073O006820612074206503043O005465787403093O0056696577696E673A2003083O00746F737472696E6703043O004E616D6501163O001220000100013O00202900010001000200061F3O0015000100010004253O00150001001220000100034O00080001000100022O002800015O001220000100043O00202900010001000500201A000100010006001218000300074O001000043O00020030130004000800090012180005000B3O0012200006000C4O001900075O00202900070007000D4O0006000200022O00170005000500060010010004000A00052O00050001000400012O00073O00017O00163O009D3O009D3O009D3O009D3O009E3O009E3O009E3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O009F3O00A13O00023O00030D3O0052656E6465725374652O70656403073O00436F2O6E656374000B4O00197O0020295O000100201A5O000200062C00023O000100052O00193O00014O00193O00024O00193O00034O00193O00044O00193O00054O00053O000200012O00073O00013O00013O000D3O0003093O0043686172616374657203073O00456E61626C6564010003023O005F4703063O00656E61626C6503063O0067657467756E030E3O0046696E6446697273744368696C64030B3O00426F6479452O666563747303043O00486561642O0103083O00506F736974696F6E03063O006D6574686F6403053O0056616C756500344O00197O0020295O00010006123O0007000100010004253O000700012O0019000100013O0030130001000200032O00073O00013O001220000100043O00202900010001000500061C0001003100013O0004253O00310001001220000100064O000800010001000200061C0001003100013O0004253O003100012O0019000100023O00202900010001000100201A000100010007001218000300084O002A00010003000200061C0001003100013O0004253O003100012O0019000100023O00202900010001000100201A000100010007001218000300094O002A00010003000200061C0001003100013O0004253O003100012O0019000100013O00301300010002000A2O0019000100034O0019000200023O00202900020002000100201A000200020007001218000400094O002A00020004000200202900020002000B0010010001000B00022O0019000100044O0019000200023O002029000200020001002029000200020008001220000300043O00202900030003000C2O001E00020002000300202900020002000D0010010001000B00020004253O003300012O0019000100013O0030130001000200032O00073O00017O00343O00B13O00B13O00B23O00B23O00B33O00B33O00B43O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B63O00B73O00B73O00B83O00B83O00B83O00B83O00B83O00B83O00B83O00B83O00B93O00B93O00B93O00B93O00B93O00B93O00B93O00B93O00B93O00B93O00BB3O00BB3O00BD3O000B3O00B03O00B03O00B03O00BD3O00BD3O00BD3O00BD3O00BD3O00BD3O00B03O00BE3O00913O00013O00013O00013O00013O00013O00013O00013O00023O00023O00023O00023O00033O00033O00033O00033O00033O00033O00043O00043O00043O00053O00053O00153O00053O00163O00163O00283O00163O00293O00293O003B3O00293O003C3O003C3O00523O003C3O00533O00533O00673O00533O00683O00683O00693O00693O00693O00693O00693O00693O00693O00693O006A3O006A3O006B3O006B3O006C3O006C3O006D3O006D3O006D3O006D3O006D3O006D3O006E3O006E3O006E3O006F3O006F3O006F3O00723O006F3O00733O00733O00733O00763O00733O00773O00773O00773O00773O00783O00783O00783O00793O00793O007A3O00813O00813O00813O00903O00903O00903O00903O00913O00913O009B3O00913O009C3O009C3O00A13O00A13O009C3O00A23O00A23O00A23O00A23O00A33O00A43O00A53O00A63O00A63O00A63O00A63O00A63O00A63O00A73O00A83O00A83O00A83O00A83O00A93O00A93O00A93O00A93O00AA3O00AB3O00AC3O00AC3O00AC3O00AD3O00AD3O00AD3O00AE3O00AE3O00AE3O00AF3O00AF3O00BE3O00BE3O00BE3O00BE3O00BE3O00BE3O00BE3O00AF3O00BE3O00",GetFEnv(),...);
