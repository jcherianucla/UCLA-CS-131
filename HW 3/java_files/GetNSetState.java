import java.util.concurrent.atomic.AtomicIntegerArray;

class GetNSetState implements State {
    private byte maxval;
    private AtomicIntegerArray atomic_array;

	// Helper class to create AtomicIntegerArray from byte array
	// With an intermediate int array because the constructor only
	// takes in an int array
	private void createAtomicArray(byte[] v){
    	int[] intArray = new int[v.length];
    	for(int i = 0; i < v.length; i++){
    		intArray[i] = v[i];
		}
		atomic_array = new AtomicIntegerArray(intArray);
	}


    GetNSetState(byte[] v) { 
    	maxval = 127;
    	createAtomicArray(v);
    }

    GetNSetState(byte[] v, byte m) { 
    	maxval = m;
    	createAtomicArray(v);
    }

    public int size() { return atomic_array.length(); }

	// Downcast the array of ints in the AtomicIntegerArray to bytes
    public byte[] current() { 
		byte[] ret = new byte[atomic_array.length()];
		for(int i = 0; i < ret.length; i++){
			ret[i] = (byte) atomic_array.get(i);
		}
		return ret;
	}

	// Use the AtomicIntegerArray to get and set the values
	// of the array in an atomic manner
	public boolean swap(int i, int j) {
		if (atomic_array.get(i) <= 0 || atomic_array.get(j) >= maxval) {
			return false;
		}
		atomic_array.getAndDecrement(i);
		atomic_array.getAndIncrement(j);
		return true;
	}
}

