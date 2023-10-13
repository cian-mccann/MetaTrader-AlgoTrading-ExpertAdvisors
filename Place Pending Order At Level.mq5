#property copyright "Cian McCann"
#property description "Ensure the Position Size Calculator inputs are defined correctly before using. Keep in mind my Entry Level can techically change if the correciton extends before making the impulse wave which tags my Open Pending Order Level line, I may want to allow extra room with my Entry Level for this scenario."
#include <Trade/Trade.mqh>
bool DisableTradingWhenLinesAreHidden;
int MaxSlippage = 0, MaxSpread, MaxEntrySLDistance, MinEntrySLDistance, MagicNumber = 0;
double MaxPositionSize;
string Commentary = "PSC-Trader";
CTrade *Trade;
enum ENTRY_TYPE
{
   Instant,
   Pending
};

int OnInit()
{
   return(INIT_SUCCEEDED);
}

void OnDeinit(const int reason)
{

}

/***** Main Function *****/ 
void OnTick()
{
   // Get the current bid price
   double bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);
      
   // Get the level of the pendingOrderTagLevel line to open the pending order at
   double pendingOrderTagLevelPrice = ObjectGetDouble(0, "pendingOrderTagLevel", OBJPROP_PRICE, 0);
  
   double sl = ObjectGetDouble(0, "StopLossLine", OBJPROP_PRICE);
   double el = ObjectGetDouble(0, "EntryLine", OBJPROP_PRICE);
   
   sl = NormalizeDouble(sl, _Digits);
   el = NormalizeDouble(el, _Digits);
   
   // Create pendingOrderTagLevel line
   if (el > sl)
   {
      createHorizontalLine(bid, true);
   } else {
      createHorizontalLine(bid, false);
   }
   
   Print("Pips between bid and pendingOrderTagLevelPrice =");
   Print(bid-pendingOrderTagLevelPrice);
   // If the bids gets to 1 pip above the moveToBreakEvenLinePrice place the pending order
   if ((bid-pendingOrderTagLevelPrice) < 0.0001 && (bid-pendingOrderTagLevelPrice) > -0.0001) {
      Print("bid == moveToBreakEvenLinePrice so calling Place Order script.");
      // Call the "Place Order" script to open the pending order
      PlacePendingOrder();
      ExpertRemove();
   }
}

void createHorizontalLine(double bid, bool isBuy)
{ 
   int pendingOrderTagLevel_found =  ObjectFind(0, "pendingOrderTagLevel");
   
   if (pendingOrderTagLevel_found < 0) {
      
      if (isBuy) {
         if(ObjectCreate(0,"pendingOrderTagLevel",OBJ_HLINE,0,0,(bid-100*_Point))) {
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_COLOR, clrDarkGreen);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_SELECTABLE,true); 
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_SELECTED,true); 
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_WIDTH,1);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_STYLE,STYLE_DOT);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_ZORDER,0); 
         }
      } else {
         if(ObjectCreate(0,"pendingOrderTagLevel",OBJ_HLINE,0,0,(bid+100*_Point))) {
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_COLOR, clrDarkGreen);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_HIDDEN,false);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_SELECTABLE,true); 
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_SELECTED,true); 
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_WIDTH,1);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_STYLE,STYLE_DOT);
            ObjectSetInteger(0,"pendingOrderTagLevel",OBJPROP_ZORDER,0); 
         }
      }
   } 
}

string FindEditObjectByPostfix(const string postfix)
{
	int obj_total = ObjectsTotal(0, 0, OBJ_EDIT);
	string name = "";
	bool found = false;
	for (int i = 0; i < obj_total; i++)
	{
		name = ObjectName(0, i, 0, OBJ_EDIT);
		string pattern = StringSubstr(name, StringLen(name) - StringLen(postfix));
		if (StringCompare(pattern, postfix) == 0)
		{
			found = true;
			break;
		}
	}
	if (found) return(name);
	else return("");
}

string FindCheckboxObjectByPostfix(const string postfix)
{
	int obj_total = ObjectsTotal(0, 0, OBJ_BITMAP_LABEL);
	string name = "";
	bool found = false;
	for (int i = 0; i < obj_total; i++)
	{
		name = ObjectName(0, i, 0, OBJ_BITMAP_LABEL);
		string pattern = StringSubstr(name, StringLen(name) - StringLen(postfix));
		if (StringCompare(pattern, postfix) == 0)
		{
			found = true;
			break;
		}
	}
	if (found) return(name);
	else return("");
}

void PlacePendingOrder()
{
   double Window;

   string ps = ""; // Position size string.
   double el = 0, sl = 0, tp = 0; // Entry level, stop-loss, and take-profit.
   ENUM_ORDER_TYPE ot; // Order type.
   ENTRY_TYPE entry_type;

   Window = ChartWindowFind(0, "Position Size Calculator" + IntegerToString(ChartID()));
   
   if (Window == -1)
   {
      // Trying to find the new version's position size object.
      ps = FindEditObjectByPostfix("m_EdtPosSize");
      ps = ObjectGetString(0, ps, OBJPROP_TEXT);
      // Trying to find the legacy version's position size object.
     	if (StringLen(ps) == 0) ps = ObjectGetString(0, "PositionSize", OBJPROP_TEXT);
	   if (StringLen(ps) == 0)
      {
         Alert("Position Size Calculator not found!");
         return;
      }
   }
   
	// Trying to find the new version's position size object.
   ps = FindEditObjectByPostfix("m_EdtPosSize");
   ps = ObjectGetString(0, ps, OBJPROP_TEXT);
   // Trying to find the legacy version's position size object.
   if (StringLen(ps) == 0) ps = ObjectGetString(0, "PositionSize", OBJPROP_TEXT);
   if (StringLen(ps) == 0)
   {
      Alert("Position Size object not found!");
      return;
   }
   
   int len = StringLen(ps);
   string ps_proc = "";
   for (int i = len - 1; i >= 0; i--)
   {
      string c = StringSubstr(ps, i, 1);
      if (c != " ") ps_proc = c + ps_proc;
      else break;
   }
   
   double PositionSize = StringToDouble(ps_proc);
   
   Print("Detected position size: ", DoubleToString(PositionSize, 2), ".");
   
   if (PositionSize <= 0)
   {
      Print("Wrong position size value!");
      return;
   }
   
   el = ObjectGetDouble(0, "EntryLine", OBJPROP_PRICE);
   if (el <= 0)
   {
      Alert("Entry Line not found!");
      return;
   }
   
   el = NormalizeDouble(el, _Digits);
   Print("Detected entry level: ", DoubleToString(el, _Digits), ".");

   double Ask = SymbolInfoDouble(Symbol(), SYMBOL_ASK);
   double Bid = SymbolInfoDouble(Symbol(), SYMBOL_BID);
   
   if ((el == Ask) || (el == Bid)) entry_type = Instant;
   else entry_type = Pending;
   
   Print("Detected entry type: ", EnumToString(entry_type), ".");
   
   sl = ObjectGetDouble(0, "StopLossLine", OBJPROP_PRICE);
   if (sl <= 0)
   {
      Alert("Stop-Loss Line not found!");
      return;
   }
   
   sl = NormalizeDouble(sl, _Digits);
   Print("Detected stop-loss level: ", DoubleToString(sl, _Digits), ".");
   
   
   tp = ObjectGetDouble(0, "TakeProfitLine", OBJPROP_PRICE);
   if (tp > 0)
   {
      tp = NormalizeDouble(tp, _Digits);
      Print("Detected take-profit level: ", DoubleToString(tp, _Digits), ".");
   }
   else Print("No take-profit detected.");
   
	// Magic number
   string EdtMagicNumber = FindEditObjectByPostfix("m_EdtMagicNumber");
   if (EdtMagicNumber != "") MagicNumber = (int)StringToInteger(ObjectGetString(0, EdtMagicNumber, OBJPROP_TEXT));
   Print("Magic number = ", MagicNumber);

	// Order commentary
   string EdtScriptCommentary = FindEditObjectByPostfix("m_EdtScriptCommentary");
   if (EdtScriptCommentary != "") Commentary = ObjectGetString(0, EdtScriptCommentary, OBJPROP_TEXT);
   Print("Order commentary = ", Commentary);

   // Checkbox
   string ChkDisableTradingWhenLinesAreHidden = FindCheckboxObjectByPostfix("m_ChkDisableTradingWhenLinesAreHiddenButton");
   if (StringLen(ChkDisableTradingWhenLinesAreHidden) > 0) DisableTradingWhenLinesAreHidden = ObjectGetInteger(0, ChkDisableTradingWhenLinesAreHidden, OBJPROP_STATE);
   Print("Disable trading when lines are hidden = ", DisableTradingWhenLinesAreHidden);

	// Entry line
   bool EntryLineHidden = false;
   int EL_Hidden = (int)ObjectGetInteger(0, "EntryLine", OBJPROP_TIMEFRAMES);
   if (EL_Hidden == OBJ_NO_PERIODS) EntryLineHidden = true; 
   Print("Entry line hidden = ", EntryLineHidden);

	if ((DisableTradingWhenLinesAreHidden) && (EntryLineHidden))
	{
		Print("Not taking a trade - lines are hidden, and indicator says not to trade when they are hidden.");
		return;
	}

	// Edits
   string EdtMaxSlippage = FindEditObjectByPostfix("m_EdtMaxSlippage");
   if (StringLen(EdtMaxSlippage) > 0) MaxSlippage = (int)StringToInteger(ObjectGetString(0, EdtMaxSlippage, OBJPROP_TEXT));
   Print("Max slippage = ", MaxSlippage);

   string EdtMaxSpread = FindEditObjectByPostfix("m_EdtMaxSpread");
   if (StringLen(EdtMaxSpread) > 0) MaxSpread = (int)StringToInteger(ObjectGetString(0, EdtMaxSpread, OBJPROP_TEXT));
   Print("Max spread = ", MaxSpread);
   
   if (MaxSpread > 0)
   {
	   int spread = (int)SymbolInfoInteger(Symbol(), SYMBOL_SPREAD);
	   if (spread > MaxSpread)
	   {
			Print("Not taking a trade - current spread (", spread, ") > maximum spread (", MaxSpread, ").");
			return;
	   }
	}
	
   string EdtMaxEntrySLDistance = FindEditObjectByPostfix("m_EdtMaxEntrySLDistance");
   if (StringLen(EdtMaxEntrySLDistance) > 0) MaxEntrySLDistance = (int)StringToInteger(ObjectGetString(0, EdtMaxEntrySLDistance, OBJPROP_TEXT));
   Print("Max Entry/SL distance = ", MaxEntrySLDistance);

   if (MaxEntrySLDistance > 0)
   {
	   int CurrentEntrySLDistance = (int)(MathAbs(sl - el) / Point());
	   if (CurrentEntrySLDistance > MaxEntrySLDistance)
	   {
			Print("Not taking a trade - current Entry/SL distance (", CurrentEntrySLDistance, ") > maximum Entry/SL distance (", MaxEntrySLDistance, ").");
			return;
	   }
	}
	
   string EdtMinEntrySLDistance = FindEditObjectByPostfix("m_EdtMinEntrySLDistance");
   if (StringLen(EdtMinEntrySLDistance) > 0) MinEntrySLDistance = (int)StringToInteger(ObjectGetString(0, EdtMinEntrySLDistance, OBJPROP_TEXT));
   Print("Min Entry/SL distance = ", MinEntrySLDistance);

   if (MinEntrySLDistance > 0)
   {
	   int CurrentEntrySLDistance = (int)(MathAbs(sl - el) / Point());
	   if (CurrentEntrySLDistance < MinEntrySLDistance)
	   {
			Print("Not taking a trade - current Entry/SL distance (", CurrentEntrySLDistance, ") < minimum Entry/SL distance (", MinEntrySLDistance, ").");
			return;
	   }
	}
	
   string EdtMaxPositionSize = FindEditObjectByPostfix("m_EdtMaxPositionSize");
   if (StringLen(EdtMaxPositionSize) > 0) MaxPositionSize = StringToDouble(ObjectGetString(0, EdtMaxPositionSize, OBJPROP_TEXT));
   Print("Max position size = ", DoubleToString(MaxPositionSize, 2));
	   
   if (MaxPositionSize > 0)
   {
	   if (PositionSize > MaxPositionSize)
	   {
			Print("Not taking a trade - position size (", PositionSize, ") > maximum position size (", MaxPositionSize, ").");
			return;
	   }
	}
	
   Trade = new CTrade;
   Trade.SetDeviationInPoints(MaxSlippage);
   if (MagicNumber > 0) Trade.SetExpertMagicNumber(MagicNumber);

	ENUM_SYMBOL_TRADE_EXECUTION Execution_Mode = (ENUM_SYMBOL_TRADE_EXECUTION)SymbolInfoInteger(Symbol(), SYMBOL_TRADE_EXEMODE);
	Print("Execution mode: ", EnumToString(Execution_Mode));

   if (SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE) == SYMBOL_FILLING_FOK)
   {
      Print("Order filling mode: Fill or Kill.");
      Trade.SetTypeFilling(ORDER_FILLING_FOK);
   }
   else if (SymbolInfoInteger(Symbol(), SYMBOL_FILLING_MODE) == SYMBOL_FILLING_IOC)
   {
      Print("Order filling mode: Immediate or Cancel.");
      Trade.SetTypeFilling(ORDER_FILLING_IOC);
   }

   if (entry_type == Pending)
   {
      // Sell
      if (sl > el)
      {
         // Stop
         if (el < Bid) ot = ORDER_TYPE_SELL_STOP;
         // Limit
         else ot = ORDER_TYPE_SELL_LIMIT;
      }
      // Buy
      else
      {
         // Stop
         if (el > Ask) ot = ORDER_TYPE_BUY_STOP;
         // Limit
         else ot = ORDER_TYPE_BUY_LIMIT;
      }
      if (!Trade.OrderOpen(Symbol(), ot, PositionSize, 0, el, sl, tp, 0, 0, Commentary))
      {
         Print("Error sending order: ", Trade.ResultRetcodeDescription() + ".");
      }
      else Print("Order executed. Ticket: ", Trade.ResultOrder(), ".");
   }
   // Instant
   else
   {
      // Sell
      if (sl > el) ot = ORDER_TYPE_SELL;
      // Buy
      else ot = ORDER_TYPE_BUY;

	   double order_sl = sl;
	   double order_tp = tp;      
	
		// Market execution mode - preparation.
		if ((Execution_Mode == SYMBOL_TRADE_EXECUTION_MARKET) && (entry_type == Instant))
		{
			// No SL/TP allowed on instant orders.
			order_sl = 0;
			order_tp = 0;
		}

      if (!Trade.PositionOpen(Symbol(), ot, PositionSize, el, order_sl, order_tp, Commentary))
      {
         Print("Error opening position: ", Trade.ResultRetcodeDescription() + ".");
      }
      else
      {
      	MqlTradeResult result;
      	Trade.Result(result);
      	ulong deal = result.deal;

      	Print("Position opened via deal ID: ", deal);

			// Market execution mode - application of SL/TP.
			if ((Execution_Mode == SYMBOL_TRADE_EXECUTION_MARKET) && (entry_type == Instant))
			{
	   		if (HistorySelect(TimeCurrent() - 60, TimeCurrent()))
	   		{
		   		if (HistoryDealSelect(deal))
		   		{
						long position = HistoryDealGetInteger(deal, DEAL_POSITION_ID);
			      	Print("Position ID: ", position);
		
			      	if (!Trade.PositionModify(position, sl, tp)) Print("Error modifying position: ", GetLastError());
			      	else Print("SL/TP applied successfully.");
			      }
			      else Print("Error selecting deal: ", GetLastError());
			   }
			   else Print("Error selecting deal history: ", GetLastError());
			}
      }
   }
         
   
   delete Trade;
}