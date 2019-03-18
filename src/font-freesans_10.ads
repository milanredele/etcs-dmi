package Font.FreeSans_10 is

   Glyphs : Glyph_Map := ('0' => (Left => 1,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 6,
                                  Bitmap_Pos => 1
                                 ),
                          '1' => (Left => 1,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 4,
                                  Bitmap_Pos => 61
                                 ),
                          '2' => (Left => 0,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 7,
                                  Bitmap_Pos => 101
                                 ),
                          '3' => (Left => 0,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 7,
                                  Bitmap_Pos => 171
                                 ),
                          '4' => (Left => 0,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 7,
                                  Bitmap_Pos => 241
                                 ),
                          '5' => (Left => 0,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 7,
                                  Bitmap_Pos => 311
                                 ),
                          '6' => (Left => 1,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 6,
                                  Bitmap_Pos => 381
                                 ),
                          '7' => (Left => 1,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 6,
                                  Bitmap_Pos => 441
                                 ),
                          '8' => (Left => 1,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 6,
                                  Bitmap_Pos => 501
                                 ),
                          '9' => (Left => 1,
                                  Top => 10,
                                  Advance_X => 8,
                                  Height => 10,
                                  Width => 6,
                                  Bitmap_Pos => 561
                                 ));

   Bitmap : Bitmap_T 
     := (
         -- codepoint 0X30
         False,True ,True ,True ,False,False, --  ***  
         True ,True ,False,False,True ,False, -- **  * 
         True ,False,False,False,True ,True , -- *   **
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,True ,True , -- *   **
         True ,True ,False,False,True ,False, -- **  * 
         False,True ,True ,True ,False,False, --  ***  
         -- codepoint 0X31
         False,False,False,True , --    *
         False,False,True ,True , --   **
         True ,True ,True ,True , -- ****
         False,False,False,True , --    *
         False,False,False,True , --    *
         False,False,False,True , --    *
         False,False,False,True , --    *
         False,False,False,True , --    *
         False,False,False,True , --    *
         False,False,False,True , --    *
         -- codepoint 0X32
         False,False,True ,True ,True ,True ,False, --   **** 
         False,True ,True ,False,False,True ,True , --  **  **
         False,True ,False,False,False,False,True , --  *    *
         False,False,False,False,False,False,True , --       *
         False,False,False,False,False,True ,True , --      **
         False,False,False,False,True ,True ,False, --     ** 
         False,False,True ,True ,False,False,False, --   **   
         False,True ,True ,False,False,False,False, --  **    
         False,True ,False,False,False,False,False, --  *     
         False,True ,True ,True ,True ,True ,True , --  ******
         -- codepoint 0X33
         False,False,True ,True ,True ,True ,False, --   **** 
         False,True ,False,False,False,True ,True , --  *   **
         False,True ,False,False,False,True ,True , --  *   **
         False,False,False,False,False,True ,True , --      **
         False,False,False,True ,True ,False,False, --    **  
         False,False,False,False,False,True ,True , --      **
         False,False,False,False,False,False,True , --       *
         False,True ,False,False,False,False,True , --  *    *
         False,True ,False,False,False,True ,True , --  *   **
         False,False,True ,True ,True ,True ,False, --   **** 
         -- codepoint 0X34
         False,False,False,False,False,True ,False, --      * 
         False,False,False,False,True ,True ,False, --     ** 
         False,False,False,True ,False,True ,False, --    * * 
         False,False,False,True ,False,True ,False, --    * * 
         False,False,True ,False,False,True ,False, --   *  * 
         False,True ,False,False,False,True ,False, --  *   * 
         False,True ,False,False,False,True ,False, --  *   * 
         True ,True ,True ,True ,True ,True ,True , -- *******
         False,False,False,False,False,True ,False, --      * 
         False,False,False,False,False,True ,False, --      * 
         -- codepoint 0X35
         False,True ,True ,True ,True ,True ,True , --  ******
         False,True ,False,False,False,False,False, --  *     
         False,True ,False,False,False,False,False, --  *     
         False,True ,True ,True ,True ,True ,False, --  ***** 
         False,True ,False,False,False,True ,True , --  *   **
         False,False,False,False,False,False,True , --       *
         False,False,False,False,False,False,True , --       *
         False,True ,False,False,False,False,True , --  *    *
         False,True ,False,False,False,True ,True , --  *   **
         False,False,True ,True ,True ,True ,False, --   **** 
         -- codepoint 0X36
         False,True ,True ,True ,True ,False, --  **** 
         True ,True ,False,False,True ,True , -- **  **
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,False,False, -- *     
         True ,True ,True ,True ,True ,False, -- ***** 
         True ,True ,False,False,True ,True , -- **  **
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,False,True , -- *    *
         True ,True ,False,False,True ,True , -- **  **
         False,True ,True ,True ,True ,False, --  **** 
         -- codepoint 0X37
         True ,True ,True ,True ,True ,True , -- ******
         False,False,False,False,False,True , --      *
         False,False,False,False,True ,False, --     * 
         False,False,False,True ,True ,False, --    ** 
         False,False,False,True ,False,False, --    *  
         False,False,True ,True ,False,False, --   **  
         False,False,True ,False,False,False, --   *   
         False,False,True ,False,False,False, --   *   
         False,True ,True ,False,False,False, --  **   
         False,True ,False,False,False,False, --  *    
         -- codepoint 0X38
         False,True ,True ,True ,True ,False, --  **** 
         True ,True ,False,False,True ,True , -- **  **
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,True ,True , -- *   **
         False,True ,True ,True ,False,False, --  ***  
         True ,False,False,False,True ,True , -- *   **
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,True ,True , -- *   **
         False,True ,True ,True ,True ,False, --  **** 
         -- codepoint 0X39
         False,True ,True ,True ,True ,False, --  **** 
         True ,False,False,False,True ,False, -- *   * 
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,False,True , -- *    *
         True ,False,False,False,True ,True , -- *   **
         False,True ,True ,True ,False,True , --  *** *
         False,False,False,False,False,True , --      *
         True ,False,False,False,True ,True , -- *   **
         True ,True ,False,False,True ,False, -- **  * 
         False,True ,True ,True ,False,False  --  ***  
        );
end;
