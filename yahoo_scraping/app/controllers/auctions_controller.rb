require 'open-uri'
require 'nokogiri'

class AuctionsController < ApplicationController
  def index
    @auctions = Auction.all
    @auctions_count = @auctions.count
  end

  def new
    @auction = Auction.new
    @auctions_count = Auction.all.count
  end

  def create
    @auction = Auction.new(auction_params)

    # URLとメールの中身が空かどうか
    if @auction[:url] == "" && @auction[:email] == ""
      redirect_to new_auction_path, flash: {notice: 'YahooオークションのURLとメールアドレスを入力してください。'}
      return
    elsif @auction[:url] == "" 
      redirect_to new_auction_path, flash: {notice: 'URLを入力してください。'}
      return
    elsif @auction[:email] == ""
      redirect_to new_auction_path, flash: {notice: 'メールアドレスを入力してください。'}
      return
    end

    # Yahooオークションの商品ページURLかどうか
    if !(@auction[:url].match(/https:\/\/page.auctions.yahoo.co.jp\/jp\/auction\//))
      redirect_to new_auction_path, flash: {notice: 'Yahooオークションの商品ページURLではありません。'}
      return
    end
    charset = nil
    html = URI.open(@auction[:url]) do |f|
        sleep(1)               # サイトに負荷をかけないためにスリープを挟む
        charset = f.charset    # 文字種別を取得
        f.read                 # htmlを読み込んで変数htmlに渡す
    end

    # nokogiriで扱えるように取得したHTMLを変換
    doc = Nokogiri::HTML.parse(html, nil, charset)
    # 商品の出品が終了しているかどうか
    if doc.at_css('div.ClosedHeader__tag') 
        redirect_to new_auction_path, flash: {notice: 'このオークションの商品はすでに終了しています。'}
        return
    end

    #aタグが入札件数とか残り時間とかの取得時に邪魔なので消す
    doc.search(:a).map &:remove
        
    # 条件分けの為に先に残り時間を取得(詳細はJSで構成されているので取得できない)
    remain_time = doc.xpath('//li[@class="Count__count Count__count--sideLine"]//dd[@class="Count__number"]').text.gsub(/(\r\n|\r|\n|\f|\t)/, "")
    if /[分]/.match(remain_time) then
        redirect_to new_auction_path, flash: {notice: '残り時間が僅かなので終了致しました。'}
        return
    end

    #即決のみ(現在価格がない)の場合はそもそもしないようにする
    if /[現在]/.match(doc.xpath('//dt[@class="Price__title"]').text) then 

        # 各必要データの取得
        # 商品名
        proname = doc.xpath('//h1[contains(@class, "Product")]').text.gsub(/(\r\n|\r|\n|\f|\t)/, "")

        # 税込価格を抜いた現在価格
        doc.xpath('//span[@class="Price__tax u-fontSize14"]').remove
        price = doc.at_xpath('//dd[@class="Price__value"]').text.gsub(/(\r\n|\r|\n|\f|\t)/, "")

        # 開始日時
        start = doc.xpath('//dl[contains(., "開始日時")]').text.gsub(/(\r\n|\r|\n|\f|\t)/, "")

        # 終了日時
        finish = doc.xpath('//dl[contains(., "終了日時")]').text.gsub(/(\r\n|\r|\n|\f|\t)/, "")

        # 入札件数
        bid_number = doc.at('//li[@class="Count__count"]//dd[@class="Count__number"]').text

        # 残り時間の文字列の整形("時間","日"の削除 + 数値に変換)
        if /["時間"]/.match(remain_time) then
            remain_time_data_H = remain_time.gsub("時間",'').to_i
        else
            remain_time_data_D = remain_time.gsub("日",'').to_i
        end

        # 価格の文字列の整形
        price_data = price.gsub(",",'').gsub("円",'').to_i

        # 入札件数の文字列の整形
        bid_data = bid_number.to_i

        # DBに各データを代入
        @auction[:proname] = proname
        @auction[:price] = price
        @auction[:start] = start
        @auction[:finish] = finish
        @auction[:bid_number] = bid_number
        @auction[:remain_time] = proname

    else
        redirect_to new_auction_path, flash: {notice: '即決価格のみなので対象外です。'}
        return
    end

    #データベースにURLとメールアドレスを保存する
    if @auction.save
      redirect_to root_path
    else 
      render :new, status: :unprocessable_entity
    end
  end

  #deleteの作成
  def destroy
    @auction = Auction.find(params[:id])
    @auction.destroy

    redirect_to root_path, status: :see_other 
  end

  private
    def auction_params
      params.require(:auction).permit(:url, :email)
    end
end
