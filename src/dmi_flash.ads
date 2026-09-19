--  ETCS DMI
--  Phase of the flashing frames (DMI 5.1.1.3.2): a frame toggles every
--  0.25 seconds between visible and not visible, starting with the
--  visible state.
--
--  One phase origin is enough. Flashing frames only exist around the
--  object or text message offered for acknowledgement (5.4.1.5), only
--  one request is presented at any given time (5.4.1.7), and the frames
--  of one request (5.4.1.6.1 has two of them with soft keys) toggle
--  together: 5.1.1.3.2 lets "the frame(s)" flash as one. The origin is
--  therefore the moment the acknowledgement service displays a request
--  (DMI_Ack calls Restart); two frames that flash independently of each
--  other do not occur.
--
--  The phase depends on the time given to Tick only (DMI_Core.Tick), so
--  that it is the same on the target, in the browser and in the tests.

package DMI_Flash is

   -- DMI 5.1.1.3.2
   Toggle_Ms : constant := 250;

   -- A flashing frame appears now: it starts in the visible state
   procedure Restart;

   -- Any Dt_Ms is accepted
   procedure Tick (Dt_Ms : Natural);

   function Frame_Visible return Boolean;

end DMI_Flash;
