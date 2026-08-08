--  semi_space_collector.ads
--  Specification for the Semi-Space Garbage Collector (Copying Collector)
--  Implements both Cheney's Iterative and standard Recursive variants.

package Semi_Space_Collector is

   --  Strong typing for object references to prevent accidental integer math
   type Object_Id is new Integer range -1 .. 1_000_000;
   Null_Id : constant Object_Id := -1;

   --  Indicates which semi-space is currently acting as From-Space
   type Space_Selector is (Space_A, Space_B);

   --  Variant record representing a memory cell (Node).
   --  During GC, active nodes are replaced with forwarding pointers.
   type Node_Kind is (Active, Forwarded);
   type Node (Kind : Node_Kind := Active) is record
      case Kind is
         when Active =>
            Value : Integer;
            Left  : Object_Id;
            Right : Object_Id;
         when Forwarded =>
            New_Id : Object_Id;
      end case;
   end record;

   --  Memory boundaries
   Space_Size : constant Integer := 1024;
   type Node_Array is array (0 .. Space_Size - 1) of Node;
   type Root_Set is array (Positive range <>) of Object_Id;

   --  The GC Heap encapsulating both semi-spaces and state pointers
   type Heap is record
      A         : Node_Array;
      B         : Node_Array;
      Current   : Space_Selector := Space_A;
      Alloc_Ptr : Integer := 0;
   end record;

   Out_Of_Memory : exception;

   --  Core API
   procedure Initialize (H : out Heap);
   
   --  Allocates a new node. Raises Out_Of_Memory if the active space is full.
   function Allocate (H     : in out Heap; 
                      Val   : Integer; 
                      Left  : Object_Id := Null_Id; 
                      Right : Object_Id := Null_Id) return Object_Id;

   --  VARIANT 1: Cheney's Algorithm (Iterative, Breadth-First)
   --  Prevents stack overflow by using the To-Space itself as a BFS queue.
   procedure Collect_Cheney (H : in out Heap; Roots : in out Root_Set);

   --  VARIANT 2: Standard Copying (Recursive, Depth-First)
   --  The naive approach. Can cause stack overflows on deep object graphs.
   procedure Collect_Recursive (H : in out Heap; Roots : in out Root_Set);

   --  Helper/Inspection Functions
   function Get_Node (H : Heap; Id : Object_Id) return Node;
   function Active_Space_Usage (H : Heap) return Integer;
   function Get_Current_Space (H : Heap) return Space_Selector;

end Semi_Space_Collector;
