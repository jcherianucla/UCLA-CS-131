import java.util.concurrent.atomic.AtomicInteger;

class BetterSorryState implements State {
    private byte maxval;
    // Create an array of AtomicIntegers so that only the objects
    // themselves are atomic and not the entire array
    private AtomicInteger[] atomic_values;

	// Helper method to fill up the atomic values array
    private void createAtomic(byte[] v){
		atomic_values = new AtomicInteger[v.length];
		for(int i = 0; i < atomic_values.length; i++){
			atomic_values[i] = new AtomicInteger(v[i]);
		}
	}

    BetterSorryState(byte[] v) { createAtomic(v); maxval = 127; }

    BetterSorryState(byte[] v, byte m) { createAtomic(v); maxval = m; }

    public int size() { return atomic_values.length; }

	// Convert all the values in the atomic_values array
	// to bytes and return them
    public byte[] current() { 
    	byte[] ret = new byte[atomic_values.length];
    	for(int i = 0; i < ret.length; i++){
    		ret[i] = (byte) atomic_values[i].get();
		}
		return ret;
	}

	// Get and atomically update the respective values in the atomic_values
	// array
	public boolean swap(int i, int j) {
		if (atomic_values[i].get() <= 0 || atomic_values[j].get() >= maxval) {
			return false;
		}
		atomic_values[i].getAndDecrement();
		atomic_values[j].getAndIncrement();
		return true;
	}
}

