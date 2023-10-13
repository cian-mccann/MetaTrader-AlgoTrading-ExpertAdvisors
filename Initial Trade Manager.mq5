#include <Trade/Trade.mqh>
#property copyright "Cian McCann"
input bool MoveToBreakEvenAfter3Hours = false;
input bool MoveToBreakEvenAfter6Hours = true;
input bool EnableMoveToBreakEvenLine = true;
input bool EnableCancelPendingOrderLine = true;
input bool EnablePlacePendingOrderAtLevel = false;
input string OrdersToDeleteWhenOpened;

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

CTrade trade;

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
   Print ("Initial Trade Manager Running.");
   
   // Get the current bid price
   double bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);
   
   // Create positions if debugging
   // createPositionsForTesting(bid);
   
   // Look for a pending order for this currency pair
   string orderSymbol = "";
   bool foundPendingOrderForPairOnChart = false;
   for (int i = 0; i < OrdersTotal(); i++) {
     if (!foundPendingOrderForPairOnChart) {
        OrderSelect(OrderGetTicket(i));
        orderSymbol = OrderGetString(ORDER_SYMBOL);
        if (orderSymbol==_Symbol) {
          foundPendingOrderForPairOnChart = true;
          break;
        }
     }
   }
   
   // Check if there is an open position on the pair on this chart,
   // if there is an open position and a pending order it's the pending order 
   // I want to operate on.
   if (PositionSelect(_Symbol)==true && !foundPendingOrderForPairOnChart) {
   
      // If the position is open but EnableMoveToBreakEvenLine is false, remove the EA
      if (!EnableMoveToBreakEvenLine) {
         Print("Position is open but MoveToBreakEvenLine is not enabled.");
         Print("Removing Intitial Trade Manager EA (1.1)");
         ExpertRemove();
      }
      
      // Create moveToBreakEvenLine and cancelPendingOrderLine lines if not already made
      ulong position_type=PositionGetInteger(POSITION_TYPE);
      createHorizontalLines(bid, position_type, 0, true);
      
      // Get moveToBreakEvenLine and cancelPendingOrderLine values
      double moveToBreakEvenLinePrice = ObjectGetDouble(0, "moveToBreakEvenLine", OBJPROP_PRICE, 0);
      double cancelPendingOrderLine = ObjectGetDouble(0, "cancelPendingOrderLine", OBJPROP_PRICE, 0);
      
      if (position_type == 0 && EnableMoveToBreakEvenLine) {  
         Print ("Found an open buy position and EnableMoveToBreakEvenLine is true.");
         Print ("Checking if bid is >=  moveToBreakEvenLinePrice");
         Print ("Bid = " + bid + ", moveToBreakEvenLinePrice = " + moveToBreakEvenLinePrice);
         // If a trade is active check if price has hit the move to break even level
         if (bid >= moveToBreakEvenLinePrice) {
         
            // Get the position ticket number 
            ulong positionTicketNumber = PositionGetInteger(POSITION_TICKET);
            
            // Get the position entry price
            int digits = Digits();
            double positionEntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double normalizedPositionEntryPrice = NormalizeDouble(positionEntryPrice, digits);
            
            // Move to Stop Loss to break even
            trade.PositionModify(positionTicketNumber, normalizedPositionEntryPrice, 0);
            Print("1.2 Moved long trade to Break Even.");
            Print("Removing Intitial Trade Manager EA (1.3)");
            ExpertRemove();
         }
      } else if (position_type == 1 && EnableMoveToBreakEvenLine) { 
         Print ("Found an open sell position and EnableMoveToBreakEvenLine is true.");
         Print ("Checking if bid is <=  moveToBreakEvenLinePrice");
         Print ("Bid = " + bid + ", moveToBreakEvenLinePrice = " + moveToBreakEvenLinePrice);
         // If a trade is active check if price has hit the move to break even level
         if (bid <= moveToBreakEvenLinePrice) {
            // Get the position ticket number 
            ulong positionTicketNumber = PositionGetInteger(POSITION_TICKET);
            
            // Get the position entry price
            int digits = Digits();
            double positionEntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
            double normalizedPositionEntryPrice = NormalizeDouble(positionEntryPrice, digits);
            
            // Move to Stop Loss to break even
            trade.PositionModify(positionTicketNumber, normalizedPositionEntryPrice, 0);
            Print("1.2 Moved short trade to Break Even.");
            Print("Removing Intitial Trade Manager EA (1.3)");
            ExpertRemove();
         }
      }
      
      // Remove any orders specified on the OrdersToDeleteWhenOpened parameter
      if (OrdersToDeleteWhenOpened != "") {
        Print("OrdersToDeleteWhenOpened has the value " + OrdersToDeleteWhenOpened);
        string OrdersToDeleteWhenOpenedSplit[]; 
        string commaCode = StringGetCharacter(",",0);
        StringSplit(OrdersToDeleteWhenOpened, commaCode, OrdersToDeleteWhenOpenedSplit);
        for (int ii = 0; ii < ArraySize(OrdersToDeleteWhenOpenedSplit); ii++) {
          Print(OrdersToDeleteWhenOpenedSplit[ii]);
          int ord_total=OrdersTotal();
          if(ord_total > 0)
          {
            for(int i=ord_total-1;i>=0;i--)
            {
              ulong ticket=OrderGetTicket(i);
              int compare = StringCompare(OrderGetString(ORDER_SYMBOL),OrdersToDeleteWhenOpenedSplit[ii],false);
              if(OrderSelect(ticket) && compare==0)
              {
                Print("Removing The " + OrdersToDeleteWhenOpenedSplit[ii] + " Pending Order (2.1)");
                trade.OrderDelete(ticket);            
              }
            }
          }
        }
      }
      
      if (MoveToBreakEvenAfter6Hours) {
         // Check if the order is open 6 hours or more
         datetime ordertime = PositionGetInteger(POSITION_TIME);
         datetime currenttime = TimeCurrent();
         int timeDifference = currenttime - ordertime;
         string timeDifferenceHoursMins =  TimeToString(timeDifference, TIME_MINUTES);
         Print("Checking if order has been open 6 hours or more:");
         Print("Order open time = " + ordertime);
         Print("Current time = " + currenttime);
         Print("Time difference = " + timeDifferenceHoursMins + " , which is " + timeDifference + " seconds.");
   
         if (timeDifference > 21600) {
           Print("Order is open for 6 hours and MoveToBreakEvenAfter6Hours is true.");
           Print("Removing Intitial Trade Manager EA (2.0)");
           // Get the position ticket number 
           ulong positionTicketNumber = PositionGetInteger(POSITION_TICKET);
            
           // Get the position entry price
           int digits = Digits();
           double positionEntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
           double normalizedPositionEntryPrice = NormalizeDouble(positionEntryPrice, digits);
           
           Print("positionEntryPrice = " + positionEntryPrice);
           Print("normalizedPositionEntryPrice = " + normalizedPositionEntryPrice);
           Print("normalizedPositionEntryPricePlus2Pips = " + normalizedPositionEntryPrice);

           // Move to Stop Loss to break even or set take profit at break even.
           double originalStopLoss = PositionGetDouble(POSITION_SL);
           if (position_type == 0) {
             trade.PositionModify(positionTicketNumber, 0, normalizedPositionEntryPrice+20*_Point);
             trade.PositionModify(positionTicketNumber, normalizedPositionEntryPrice+20*_Point, 0);
           } else {
             trade.PositionModify(positionTicketNumber, 0, normalizedPositionEntryPrice-20*_Point);
             trade.PositionModify(positionTicketNumber, normalizedPositionEntryPrice-20*_Point, 0);
           }
           
           if (PositionGetDouble(POSITION_SL) == 0.0) {
             // Set stop loss back to original, a take profit was set and the stop loss was wiped
             trade.PositionModify(positionTicketNumber, originalStopLoss, PositionGetDouble(POSITION_TP));
           }
           
           ExpertRemove();
         } else {
           Print("Order not open for 6 hours yet");
         }
      }
         
      if (MoveToBreakEvenAfter3Hours) {
         // Check if the order is open 3 hours or more
         datetime ordertime = PositionGetInteger(POSITION_TIME);
         datetime currenttime = TimeCurrent();
         int timeDifference = currenttime - ordertime;
         string timeDifferenceHoursMins =  TimeToString(timeDifference, TIME_MINUTES);
         Print("Checking if order has been open 3 hours or more:");
         Print("Order open time = " + ordertime);
         Print("Current time = " + currenttime);
         Print("Time difference = " + timeDifferenceHoursMins + " , which is " + timeDifference + " seconds.");
   
         if (timeDifference > 10800) {
           Print("Order is open for 3 hours and MoveToBreakEvenAfter3Hours is true.");
           Print("Removing Intitial Trade Manager EA (2.0)");
           // Get the position ticket number 
           ulong positionTicketNumber = PositionGetInteger(POSITION_TICKET);
            
           // Get the position entry price
           int digits = Digits();
           double positionEntryPrice = PositionGetDouble(POSITION_PRICE_OPEN);
           double normalizedPositionEntryPrice = NormalizeDouble(positionEntryPrice, digits);
           
           Print("positionEntryPrice = " + positionEntryPrice);
           Print("normalizedPositionEntryPrice = " + normalizedPositionEntryPrice);
           Print("normalizedPositionEntryPricePlus2Pips = " + normalizedPositionEntryPrice);

           // Move to Stop Loss to break even or set take profit at break even.
           double originalStopLoss = PositionGetDouble(POSITION_SL);
           if (position_type == 0) {
             trade.PositionModify(positionTicketNumber, 0, normalizedPositionEntryPrice+20*_Point);
             trade.PositionModify(positionTicketNumber, normalizedPositionEntryPrice+20*_Point, 0);
           } else {
             trade.PositionModify(positionTicketNumber, 0, normalizedPositionEntryPrice-20*_Point);
             trade.PositionModify(positionTicketNumber, normalizedPositionEntryPrice-20*_Point, 0);
           }
           
           if (PositionGetDouble(POSITION_SL) == 0.0) {
             // Set stop loss back to original, a take profit was set and the stop loss was wiped
             trade.PositionModify(positionTicketNumber, originalStopLoss, PositionGetDouble(POSITION_TP));
           }
           
           ExpertRemove();
         } else {
           Print("Order not open for 3 hours yet");
         }
      }
   } else { // If there is a pending order active on this chart, or I have set an EnablePlacePendingOrderAtLevel
      
      if (!foundPendingOrderForPairOnChart && !EnablePlacePendingOrderAtLevel) {
        Print("There is no pending order or open order active on this pair.");
        Print("EnablePlacePendingOrderAtLevel is also set to false.");
        Print("Removing Intitial Trade Manager EA (1.4)");
        ExpertRemove();
      }

      if (foundPendingOrderForPairOnChart) {
         if (!EnableCancelPendingOrderLine) {
           Print("Position isPending order but EnableCancelPendingOrderLine is not enabled.");
           Print("Removing Intitial Trade Manager EA (1.5)");
           ExpertRemove();
         }
      
         int pendingOrderType = OrderGetInteger(ORDER_TYPE); // ORDER_TYPE 5 = sell stop, ORDER_TYPE 4 = buy stop
         int pendingOrderTicketNum = OrderGetInteger(ORDER_TICKET);
         
         // Create moveToBreakEvenLine and cancelPendingOrderLine lines if not already made
         ulong position_type=PositionGetInteger(POSITION_TYPE);
         createHorizontalLines(bid, position_type, pendingOrderType, false);
      
         // Get moveToBreakEvenLine and cancelPendingOrderLine values
         double moveToBreakEvenLinePrice = ObjectGetDouble(0, "moveToBreakEvenLine", OBJPROP_PRICE, 0);
         double cancelPendingOrderLine = ObjectGetDouble(0, "cancelPendingOrderLine", OBJPROP_PRICE, 0);
         
         if (pendingOrderType == 4 && EnableCancelPendingOrderLine) { 
            Print ("Found a buy pending order and EnableCancelPendingOrderLine is true.");
            Print ("Checking if bid is <=  cancelPendingOrderLine");
            Print ("Bid = " + bid + ", cancelPendingOrderLine = " + cancelPendingOrderLine);
            if (bid <= cancelPendingOrderLine) {
               int ord_total=OrdersTotal();
               if(ord_total > 0)
               {
                  for(int i=ord_total-1;i>=0;i--)
                  {
                     ulong ticket=OrderGetTicket(i);
                     if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL)==Symbol())
                     {
                        trade.OrderDelete(ticket);
                        Print("Removed pending order.");
                        Print("Removing Intitial Trade Manager EA (1.6)");
                        ExpertRemove();
                     }
                  }
               }
            }
         } else if (pendingOrderType == 5 && EnableCancelPendingOrderLine) { 
            Print ("Found a sell pending order and EnableCancelPendingOrderLine is true.");
            Print ("Checking if bid is >=  cancelPendingOrderLine");
            Print ("Bid = " + bid + ", cancelPendingOrderLine = " + cancelPendingOrderLine);
            if (bid >= cancelPendingOrderLine) {
               int ord_total=OrdersTotal();
               if(ord_total > 0)
               {
                  for(int i=ord_total-1;i>=0;i--)
                  {
                     ulong ticket=OrderGetTicket(i);
                     if(OrderSelect(ticket) && OrderGetString(ORDER_SYMBOL)==Symbol())
                     {
                        trade.OrderDelete(ticket);
                        Print("Removed pending order.");
                        Print("Removing Intitial Trade Manager EA (1.7)");
                        ExpertRemove();
                     }
                  }
               }
            }
         }
      } else if (EnablePlacePendingOrderAtLevel && !foundPendingOrderForPairOnChart) {
         // If there is no order or position active and EnablePlacePendingOrderAtLevel is true
         
         // Get the current bid price
         double bidPrice = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);
         
         int StopLossLineFound =  ObjectFind(0, "StopLossLine");
         int EntryLineFound =  ObjectFind(0, "EntryLine");
         Print(StopLossLineFound);
         
         if (StopLossLineFound >= 0 && EntryLineFound >= 0) {
            createHorizontalLines(bidPrice, 0, 0, true);
         
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
            
            // Get the level of the pendingOrderTagLevel line to open the pending order at
            double pendingOrderTagLevelPrice = ObjectGetDouble(0, "pendingOrderTagLevel", OBJPROP_PRICE, 0);
            
            Print("Pips between bid and pendingOrderTagLevelPrice =");
            Print(bidPrice-pendingOrderTagLevelPrice);
            // If the bids gets to withing 1 pip of the moveToBreakEvenLinePrice place the pending order
            if ((bidPrice-pendingOrderTagLevelPrice) < 0.0001 && (bidPrice-pendingOrderTagLevelPrice) > -0.0001) {
               Print("bidPrice == moveToBreakEvenLinePrice so calling Place Order script.");
               // Call the "Place Order" script to open the pending order
               PlacePendingOrder();
            }
            
            // If the bids gets to within 1 pip of the EntryLine remove the EA as the entry line will need to be adjusted
            if ((el-pendingOrderTagLevelPrice) < 0.0001 && (el-pendingOrderTagLevelPrice) > -0.0001) {
               Print("bidPrice == EntryLine so removing EA. (2.2");
               // Call the "Place Order" script to open the pending order
               ExpertRemove();
            }
            
         } else {
            Print("EnablePlacePendingOrderAtLevel is set to true but the Position Size Calculator is not active.");
            Print("Removing Intitial Trade Manager EA (1.8)");
            ExpertRemove();
         }
      } else if (!EnablePlacePendingOrderAtLevel && !foundPendingOrderForPairOnChart) {
            Print("EnablePlacePendingOrderAtLevel is set to true but the Position Size Calculator is not active or there is no active position or order.");
            Print("Removing Intitial Trade Manager EA (1.9)");
            ExpertRemove();
      }
   } 
}

void createHorizontalLines(double bid, ulong position_type, int pendingOrderType, bool orderIsActiveSoNotAPendingOrder)
{    

   // Create move to break even line if it is not already created
   int breakEvenLineFound =  ObjectFind(0, "moveToBreakEvenLine");
   if (breakEvenLineFound < 0 && EnableMoveToBreakEvenLine) {
      double breakEvenLineInitialLevel;
      if (orderIsActiveSoNotAPendingOrder) { 
         if (position_type == 0) {
            breakEvenLineInitialLevel = (bid+300*_Point);
         } else if (position_type == 1) {
            breakEvenLineInitialLevel = (bid-300*_Point);
         }
      } else if (!orderIsActiveSoNotAPendingOrder) {
         if (pendingOrderType == 4) {
            breakEvenLineInitialLevel = (bid+300*_Point);
         } else if (pendingOrderType == 5) {
            breakEvenLineInitialLevel = (bid-300*_Point);
         }
      }
      
      if(ObjectCreate(0,"moveToBreakEvenLine",OBJ_HLINE,0,0,breakEvenLineInitialLevel)) {
         ObjectSetInteger(0,"moveToBreakEvenLine",OBJPROP_COLOR, clrCyan);
         ObjectSetInteger(0,"moveToBreakEvenLine",OBJPROP_HIDDEN,false);
         ObjectSetInteger(0,"moveToBreakEvenLine",OBJPROP_SELECTABLE,true); 
         ObjectSetInteger(0,"moveToBreakEvenLine",OBJPROP_SELECTED,true); 
         ObjectSetInteger(0,"moveToBreakEvenLine",OBJPROP_WIDTH,1);
         ObjectSetInteger(0,"moveToBreakEvenLine",OBJPROP_STYLE,STYLE_DOT);
         ObjectSetInteger(0,"moveToBreakEvenLine",OBJPROP_ZORDER,0); 
      }
   } 
   
   // Create cancel pending order line if it is not already created
   int cancelPendingOrderLineFound =  ObjectFind(0, "cancelPendingOrderLine");
   if (cancelPendingOrderLineFound < 0 && EnableCancelPendingOrderLine) {
      double cancelPendingOrderLineInitialLevel;
      
      if (orderIsActiveSoNotAPendingOrder) {
         if (position_type == 0) {
            cancelPendingOrderLineInitialLevel = (bid-300*_Point);
         } else if (position_type == 1) {
            cancelPendingOrderLineInitialLevel = (bid+300*_Point);
         }
      } else if (!orderIsActiveSoNotAPendingOrder) {
         if (pendingOrderType == 4) {
            cancelPendingOrderLineInitialLevel = (bid-300*_Point);
         } else if (pendingOrderType == 5) {
            cancelPendingOrderLineInitialLevel = (bid+300*_Point);
         }
      }
      
      if(ObjectCreate(0,"cancelPendingOrderLine",OBJ_HLINE,0,0,cancelPendingOrderLineInitialLevel)) {
         ObjectSetInteger(0,"cancelPendingOrderLine",OBJPROP_COLOR, clrOrange);
         ObjectSetInteger(0,"cancelPendingOrderLine",OBJPROP_HIDDEN,false);
         ObjectSetInteger(0,"cancelPendingOrderLine",OBJPROP_SELECTABLE,true); 
         ObjectSetInteger(0,"cancelPendingOrderLine",OBJPROP_SELECTED,true); 
         ObjectSetInteger(0,"cancelPendingOrderLine",OBJPROP_WIDTH,1);
         ObjectSetInteger(0,"cancelPendingOrderLine",OBJPROP_STYLE,STYLE_DOT);
         ObjectSetInteger(0,"cancelPendingOrderLine",OBJPROP_ZORDER,0);
      }
   }
}

void createPositionsForTesting (double bid) {
   
   if (PositionsTotal() < 1 ) {
     //trade.Sell(0.10,NULL,bid,(bid+1000*_Point),NULL, NULL);
     //trade.Buy(0.10,NULL,bid,(bid-1000*_Point),NULL, NULL);
   }
   
   if (OrdersTotal() < 1) {
     //trade.SellStop(.10,1.15840,NULL,(bid+1000*_Point),NULL,NULL,NULL,NULL);
     //trade.BuyStop(.10,1.16060,NULL,(bid-1000*_Point),NULL,NULL,NULL,NULL);
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