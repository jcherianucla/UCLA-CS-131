import java.util.concurrent.locks.ReentrantLock;

class BetterSafeState implements State {
	private byte[] value;
	private byte maxval;
	// Create a re-entrant lock (so that it is still
	// safe when the thread comes back to the execution of
	// the locked code)
	private ReentrantLock safeLock;

	BetterSafeState(byte[] v) { value = v; maxval = 127; safeLock = new ReentrantLock();}

	BetterSafeState(byte[] v, byte m) { value = v; maxval = m; safeLock = new ReentrantLock(); }

	public int size() { return value.length; }

	public byte[] current() { return value; }

	// Lock only the critical sections and unlock before returning
	// to prevent deadlock
	public boolean swap(int i, int j) {
		safeLock.lock();
		if (value[i] <= 0 || value[j] >= maxval) {
			safeLock.unlock();
			return false;
		}
		value[i]--;
		value[j]++;
		safeLock.unlock();
		return true;
	}
}

