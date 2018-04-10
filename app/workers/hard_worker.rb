class HardWorker
  include Sidekiq::Worker
 # 定时任务
  def perform(*args)
 # 睡眠10秒
  	sleep(10)
 # 输出 "Things are happening."
    Sidekiq::Logging.logger.info "Things are happening."
  end
end
