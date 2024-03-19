require_relative '../../../../app/core/model/global_lock'

RSpec.describe PatchKitTools::Model::GlobalLock do
  let(:resource) { 'test' }
  let(:owner) { 'test' }
  let(:lock) { described_class.new(resource: resource, owner: owner, status: 'allow', queue_position: 0)}
  let(:unacquired_lock) { described_class.new(resource: resource, owner: owner, status: 'wait', queue_position: 1)}
  let(:lock_status) { described_class.wait_for(resource: resource) }

  describe '.acquire' do
    # acquire_inner to return {status: 'allow', queue_position: 0, resource: resource, owner: owner}
    before do
      allow(described_class).to receive(:acquire_inner)
        .with(resource, error_message: "Error acquiring global lock: {}")
        .and_return({status: 'allow', queue_position: 0, resource: resource, owner: owner})
    end

    it 'acquires a lock' do
      expect(lock).to be_a described_class
    end

    describe 'returned lock object' do
      subject { lock }

      it 'has resource' do
        expect(subject.resource).to eq resource
      end

      it 'has owner' do
        expect(subject.owner).to eq owner
      end

      it 'has status' do
        expect(subject.status).to eq 'allow'
      end

      it 'has queue_position' do
        expect(subject.queue_position).to eq 0
      end
    end
  end

  describe '.wait_for' do

    context 'when lock is acquired' do
      before do
        allow(described_class).to receive(:acquire)
          .with(resource: resource)
          .and_return(lock)
      end

      it 'returns a lock' do
        expect(lock_status).to be_a described_class
      end

      it 'has the thread running' do
        expect(lock_status.thread).to be_a Thread
        # it is alive
        expect(lock_status.thread.alive?).to be true
      end
    end

    context 'when lock is not acquired for the first time, but is on the second time' do
      before do
        allow(described_class).to receive(:acquire)
          .with(resource: resource)
          .and_return(unacquired_lock, lock)
      end

      it 'returns a lock' do
        lock = described_class.wait_for(resource: resource)
        expect(lock).to be_a described_class
      end
    end
  end

  # describe '#release' do
  #   it 'releases a lock' do
  #     expect(lock.release).to be_nil
  #   end
  # end
end