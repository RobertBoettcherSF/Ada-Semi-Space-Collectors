--  semi_space_collector.adb
--  Implementation of the Semi-Space Garbage Collector

package body Semi_Space_Collector is

   procedure Initialize (H : out Heap) is
   begin
      H.Current := Space_A;
      H.Alloc_Ptr := 0;
   end Initialize;

   function Allocate (H     : in out Heap; 
                      Val   : Integer; 
                      Left  : Object_Id := Null_Id; 
                      Right : Object_Id := Null_Id) return Object_Id is
      New_Id : Object_Id;
   begin
      if H.Alloc_Ptr >= Space_Size then
         raise Out_Of_Memory;
      end if;

      New_Id := Object_Id (H.Alloc_Ptr);
      
      --  Allocate in the currently active From-Space
      if H.Current = Space_A then
         H.A (Integer (New_Id)) := (Kind => Active, Value => Val, Left => Left, Right => Right);
      else
         H.B (Integer (New_Id)) := (Kind => Active, Value => Val, Left => Left, Right => Right);
      end if;
      
      H.Alloc_Ptr := H.Alloc_Ptr + 1;
      return New_Id;
   end Allocate;

   -----------------------------------------------------------------------------
   --  VARIANT 1: Cheney's Algorithm (Iterative)
   -----------------------------------------------------------------------------
   procedure Collect_Cheney (H : in out Heap; Roots : in out Root_Set) is
      Old_Current : constant Space_Selector := H.Current;
      Scan_Ptr    : Integer := 0;

      --  Helper to copy a single node and leave a forwarding pointer
      function Copy (Id : Object_Id) return Object_Id is
         Old_Node : Node;
         New_Id   : Object_Id;
      begin
         if Id = Null_Id then
            return Null_Id;
         end if;

         --  Fetch node from From-Space
         Old_Node := (if Old_Current = Space_A then H.A (Integer (Id)) else H.B (Integer (Id)));

         --  If already copied, return the forwarding address
         if Old_Node.Kind = Forwarded then
            return Old_Node.New_Id;
         end if;

         if H.Alloc_Ptr >= Space_Size then
            raise Out_Of_Memory;
         end if;

         New_Id := Object_Id (H.Alloc_Ptr);
         
         --  Copy to To-Space
         if H.Current = Space_A then
            H.A (Integer (New_Id)) := Old_Node;
         else
            H.B (Integer (New_Id)) := Old_Node;
         end if;
         H.Alloc_Ptr := H.Alloc_Ptr + 1;

         --  Leave forwarding pointer in From-Space
         if Old_Current = Space_A then
            H.A (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         else
            H.B (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         end if;

         return New_Id;
      end Copy;

   begin
      --  1. Swap spaces
      H.Current := (if H.Current = Space_A then Space_B else Space_A);
      H.Alloc_Ptr := 0;

      --  2. Copy all roots (This enqueues them in To-Space)
      for I in Roots'Range loop
         Roots (I) := Copy (Roots (I));
      end loop;

      --  3. Scan To-Space (Cheney's BFS traversal queue)
      while Scan_Ptr < H.Alloc_Ptr loop
         declare
            N : Node := (if H.Current = Space_A then H.A (Scan_Ptr) else H.B (Scan_Ptr));
         begin
            --  Update children with new locations, copying them if necessary
            N.Left  := Copy (N.Left);
            N.Right := Copy (N.Right);
            
            --  Write updated node back to To-Space
            if H.Current = Space_A then
               H.A (Scan_Ptr) := N;
            else
               H.B (Scan_Ptr) := N;
            end if;
         end;
         Scan_Ptr := Scan_Ptr + 1;
      end loop;
   end Collect_Cheney;

   -----------------------------------------------------------------------------
   --  VARIANT 2: Standard Recursive Collection
   -----------------------------------------------------------------------------
   procedure Collect_Recursive (H : in out Heap; Roots : in out Root_Set) is
      Old_Current : constant Space_Selector := H.Current;

      function Copy_Rec (Id : Object_Id) return Object_Id is
         Old_Node : Node;
         New_Id   : Object_Id;
      begin
         if Id = Null_Id then
            return Null_Id;
         end if;

         Old_Node := (if Old_Current = Space_A then H.A (Integer (Id)) else H.B (Integer (Id)));

         if Old_Node.Kind = Forwarded then
            return Old_Node.New_Id;
         end if;

         if H.Alloc_Ptr >= Space_Size then
            raise Out_Of_Memory;
         end if;

         --  Allocate space in To-Space
         New_Id := Object_Id (H.Alloc_Ptr);
         H.Alloc_Ptr := H.Alloc_Ptr + 1;
         
         --  Leave forwarding pointer immediately to handle cyclic graphs
         if Old_Current = Space_A then
            H.A (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         else
            H.B (Integer (Id)) := (Kind => Forwarded, New_Id => New_Id);
         end if;

         --  Recursively copy children (Depth-First)
         Old_Node.Left  := Copy_Rec (Old_Node.Left);
         Old_Node.Right := Copy_Rec (Old_Node.Right);

         --  Write completed node to To-Space
         if H.Current = Space_A then
            H.A (Integer (New_Id)) := Old_Node;
         else
            H.B (Integer (New_Id)) := Old_Node;
         end if;

         return New_Id;
      end Copy_Rec;
   begin
      --  Swap spaces
      H.Current := (if H.Current = Space_A then Space_B else Space_A);
      H.Alloc_Ptr := 0;

      --  Traverse roots recursively
      for I in Roots'Range loop
         Roots (I) := Copy_Rec (Roots (I));
      end loop;
   end Collect_Recursive;

   -----------------------------------------------------------------------------
   --  Helpers
   -----------------------------------------------------------------------------
   function Get_Node (H : Heap; Id : Object_Id) return Node is
   begin
      if H.Current = Space_A then
         return H.A (Integer (Id));
      else
         return H.B (Integer (Id));
      end if;
   end Get_Node;

   function Active_Space_Usage (H : Heap) return Integer is
   begin
      return H.Alloc_Ptr;
   end Active_Space_Usage;

   function Get_Current_Space (H : Heap) return Space_Selector is
   begin
      return H.Current;
   end Get_Current_Space;

end Semi_Space_Collector;
