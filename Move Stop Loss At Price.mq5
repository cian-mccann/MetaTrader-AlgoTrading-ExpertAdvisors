#include <Trade/Trade.mqh>
#property copyright "Cian McCann"
input double LevelToMoveStopLossToLine_InitialLevel;
input double LevelToMoveStopLossAtLine_InitialLevel;

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
   Print ("Move Stop Loss At Price EA Running.");
   
   // Get the current Bid price
   double bid = NormalizeDouble(SymbolInfoDouble(_Symbol,SYMBOL_BID), _Digits);
   
   // Create positions if debugging
   // createPositionsForTesting(bid);
   
   // Check if there is an open position
   if (PositionSelect(_Symbol)==true) {
      
      // Create levelToMoveStopLossAt and levelToMoveStopLossTo lines if not already made
      ulong position_type=PositionGetInteger(POSITION_TYPE);
      createHorizontalLines(bid, position_type);
      
      // Get levelToMoveStopLossAtLine and levelToMoveStopLossTo values
      double levelToMoveStopLossAtPrice = ObjectGetDouble(0, "levelToMoveStopLossAt", OBJPROP_PRICE, 0);
      double levelToMoveStopLossToPrice = ObjectGetDouble(0, "levelToMoveStopLossTo", OBJPROP_PRICE, 0);
      
      if (position_type == 0) {  
         Print ("Found an open buy position.");
         Print ("Checking if position of bid is >= levelToMoveStopLossAtPrice");
         Print ("Bid = " + bid + ", levelToMoveStopLossAtPrice = " + levelToMoveStopLossAtPrice);
         // If a trade is active check if price has hit the levelToMoveStopLossAtPrice
         if (bid >= levelToMoveStopLossAtPrice) {
         
            // Get the position ticket number 
            ulong positionTicketNumber = PositionGetInteger(POSITION_TICKET);
            
            // Get the normalized levelToMoveStopLossToPrice price
            int digits = Digits();
            double normalizedLevelToMoveStopLossToPrice = NormalizeDouble(levelToMoveStopLossToPrice, digits);
            
            // Move to Stop Loss to levelToMoveStopLossToPrice
            trade.PositionModify(positionTicketNumber, normalizedLevelToMoveStopLossToPrice, 0);
            Print("1.1 Moved trade (buy) to levelToMoveStopLossToPrice which is " + levelToMoveStopLossToPrice);
            ExpertRemove();
         }
      } else if (position_type == 1) { 
         Print ("Found an open sell position.");
         Print ("Checking if position of bid is <=  levelToMoveStopLossAtPrice");
         Print ("Bid = " + bid + ", levelToMoveStopLossAtPrice = " + levelToMoveStopLossAtPrice);
         // If a trade is active check if price has hit the levelToMoveStopLossAtPrice
         if (bid <= levelToMoveStopLossAtPrice) {
            // Get the position ticket number 
            ulong positionTicketNumber = PositionGetInteger(POSITION_TICKET);
            
            // Get the normalized levelToMoveStopLossToPrice price
            int digits = Digits();
            double normalizedLevelToMoveStopLossToPrice = NormalizeDouble(levelToMoveStopLossToPrice, digits);
            
            // Move to Stop Loss to levelToMoveStopLossToPrice
            trade.PositionModify(positionTicketNumber, normalizedLevelToMoveStopLossToPrice, 0);
            Print("1.1 Moved trade (buy) to levelToMoveStopLossToPrice which is " + levelToMoveStopLossToPrice);
            ExpertRemove();
         }
      }
   } else {
      Print("Removing Move Stop Loss At Price EA.");
      Print("There is no open order active.");
      
      ExpertRemove();
   }
}

void createHorizontalLines(double bid, ulong position_type)
{    
   // Create levelToMoveStopLossAt line
   int levelToMoveStopLossAtLineFound =  ObjectFind(0, "levelToMoveStopLossAt");
   if (levelToMoveStopLossAtLineFound < 0) {
      double levelToMoveStopLossAtLineLevel;
      if (LevelToMoveStopLossAtLine_InitialLevel != 0) {
         levelToMoveStopLossAtLineLevel = LevelToMoveStopLossAtLine_InitialLevel;
      }
      else { 
         if (position_type == 0) {
            levelToMoveStopLossAtLineLevel = (bid+400*_Point);
         } else if (position_type == 1) {
            levelToMoveStopLossAtLineLevel = (bid-400*_Point);
         }
     }
   
     if(ObjectCreate(0,"levelToMoveStopLossAt",OBJ_HLINE,0,0,levelToMoveStopLossAtLineLevel)) {
         ObjectSetInteger(0,"levelToMoveStopLossAt",OBJPROP_COLOR, clrCyan);
         ObjectSetInteger(0,"levelToMoveStopLossAt",OBJPROP_HIDDEN,false);
         ObjectSetInteger(0,"levelToMoveStopLossAt",OBJPROP_SELECTABLE,true); 
         ObjectSetInteger(0,"levelToMoveStopLossAt",OBJPROP_SELECTED,true); 
         ObjectSetInteger(0,"levelToMoveStopLossAt",OBJPROP_WIDTH,1);
         ObjectSetInteger(0,"levelToMoveStopLossAt",OBJPROP_STYLE,STYLE_DOT);
         ObjectSetInteger(0,"levelToMoveStopLossAt",OBJPROP_ZORDER,0); 
     }
   } 
   
   // Create levelToMoveStopLossTo line
   int levelToMoveStopLossToLineFound =  ObjectFind(0, "levelToMoveStopLossTo");
   if (levelToMoveStopLossToLineFound < 0) {
      double levelToMoveStopLossToLineLevel;
      if (LevelToMoveStopLossToLine_InitialLevel != 0) {
         levelToMoveStopLossToLineLevel = LevelToMoveStopLossToLine_InitialLevel;
      }
      else { 
         if (position_type == 0) {
            levelToMoveStopLossToLineLevel = (bid+400*_Point);
         } else if (position_type == 1) {
            levelToMoveStopLossToLineLevel = (bid-400*_Point);
         }
     }
      
      if(ObjectCreate(0,"levelToMoveStopLossTo",OBJ_HLINE,0,0,levelToMoveStopLossToLineLevel)) {
         ObjectSetInteger(0,"levelToMoveStopLossTo",OBJPROP_COLOR, clrCyan);
         ObjectSetInteger(0,"levelToMoveStopLossTo",OBJPROP_HIDDEN,false);
         ObjectSetInteger(0,"levelToMoveStopLossTo",OBJPROP_SELECTABLE,true); 
         ObjectSetInteger(0,"levelToMoveStopLossTo",OBJPROP_SELECTED,true); 
         ObjectSetInteger(0,"levelToMoveStopLossTo",OBJPROP_WIDTH,1);
         ObjectSetInteger(0,"levelToMoveStopLossTo",OBJPROP_STYLE,STYLE_DOT);
         ObjectSetInteger(0,"levelToMoveStopLossTo",OBJPROP_ZORDER,0); 
      }
   }
}

void createPositionsForTesting (double bid) {
   
   if (PositionsTotal() < 1 ) {
     trade.Sell(0.10,NULL,bid,(bid+1000*_Point),NULL, NULL);
    // trade.Buy(0.10,NULL,bid,(bid-1000*_Point),NULL, NULL);
   }
   
   if (OrdersTotal() < 1) {
      //trade.SellStop(.10,1.15840,NULL,(bid+1000*_Point),NULL,NULL,NULL,NULL);
      //trade.BuyStop(.10,1.16060,NULL,(bid-1000*_Point),NULL,NULL,NULL,NULL);
   }

}
