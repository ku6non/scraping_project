class CreateAuctions < ActiveRecord::Migration[7.0]
  def change
    create_table :auctions do |t|
      t.string :url           #URL
      t.string :email         #メールアドレス
      t.string :proname       #商品名
      t.string :price         #価格
      t.string :start         #開始日時
      t.string :finish        #終了日時
      t.string :bid_number    #入札件数
      t.string :remain_time   #残り時間

      t.timestamps
    end
  end
end
