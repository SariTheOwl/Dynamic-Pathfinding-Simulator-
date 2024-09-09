class_name Priority_util

class Priority:

    var k1: float
    var k2: float

    func _init(k1_new, k2_new):
        self.k1 = k1_new
        self.k2 = k2_new

    func _lt_(other: Priority) -> bool:
        return self.k1 < other.k1 or (self.k1 == other.k1 and self.k2 < other.k2)
    
    func _le_(other: Priority) -> bool:
        return self.k1 < other.k1 or (self.k1 == other.k1 and self.k2 <= other.k2)


class PriorityNode:
    var priority: Priority
    var vertex: Vector3

    func _init(p, v):
        self.priority = p
        self.vertex = v 

    func _lt_(other: PriorityNode) -> bool:
        return self.priority._lt_(other.priority)
    
    func _le_(other: PriorityNode) -> bool:
        return self.priority._le_(other.priority)

class PriorityQueue:
    var heap: Array
    var vertices_in_heap: Array

    func _init():
            self.heap = []
            self.vertices_in_heap = []
    
    func top():
        return self.heap[0].vertex
    
    func top_key():
        if self.heap.size() == 0:
            return Priority.new(INF,INF)
        else:
            return self.heap[0].priority
    
    func pop():
        var lastelt = self.heap.pop_front()
        self.vertices_in_heap.erase(lastelt)
        var return_item
        if(heap):
            return_item = heap[0]
            heap[0] = lastelt
            _siftup(0)
        else:
            return_item = lastelt
        return return_item
    
    func insert(vertex, priority):
        var item = PriorityNode.new(priority, vertex)
        self.vertices_in_heap.append(vertex)
        self.heap.append(item)
        self._siftdown(0, self.heap.size() - 1)

    func remove(vertex):
        for i in range(heap.size()):
            if heap[i].vertex == vertex:
                # Replace the element to be removed with the last element
                heap[i] = heap[heap.size() - 1]
                heap.remove_at(heap.size() - 1)
                break
        build_heap()

    func update(vertex, priority):
        for i in range(heap.size()):
            if heap[i].vertex == vertex:
                heap[i].priority = priority
                break
        build_heap()

    # Transform list into a heap, in-place, in O(len(x)) time.
    func build_heap():
        var n:int = heap.size()
        for i in range(n / 2, -1, -1):
            _siftup(i)

    # 'heap' is a heap at all indices >= startpos, except possibly for pos.
    # pos is the index of a leaf with a possibly out-of-order value.
    # Restore the heap invariant.
    func _siftdown(startpos, pos):
        var newitem = heap[pos]
        while pos > startpos:
            var parentpos = (pos - 1) >> 1  # Get parent position
            var parent = heap[parentpos]
            if newitem.priority < parent.priority:  # Adjust comparison if necessary
                heap[pos] = parent
                pos = parentpos
            else:
                break
        heap[pos] = newitem

    func _siftup(pos):
        var endpos = heap.size()
        var startpos = pos
        var newitem = heap[pos]
        var childpos = 2 * pos + 1  # leftmost child position
        while childpos < endpos:
            var rightpos = childpos + 1
            if rightpos < endpos and heap[childpos].priority >= heap[rightpos].priority:
                childpos = rightpos
            heap[pos] = heap[childpos]
            pos = childpos
            childpos = 2 * pos + 1
        heap[pos] = newitem
        _siftdown(startpos, pos)