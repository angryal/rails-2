class Offer < ActiveRecord::Base
  attr_accessible :listed_at, :bidask, :price, :quantity, :currency,
                  :market_id, :market
  validates :price, :quantity, :presence => true
  belongs_to :depth_run
  belongs_to :market

  scope :asks, where(bidask: "ask")
  scope :bids, where(bidask: "bid")
  scope :trades, lambda {|from_currency, to_currency| joins(:market).where(['markets.from_currency = ? and markets.to_currency = ?', from_currency, to_currency])}

  def balance(currency = market.from_currency)
    currency_check!(currency)
    Balance.new(amount: price_calc(currency), currency: currency)
  end

  def cost(quantity = quantity)
    if currency == market.from_currency
      balance*quantity
    elsif currency == market.to_currency
      Balance.new(amount: quantity, currency: market.from_currency)
    end
  end

  def produces(quantity = quantity)
    if currency == market.from_currency
      Balance.new(amount: quantity, currency: market.to_currency)
    elsif currency == market.to_currency
      balance(currency)*quantity
    end
  end

  def spend!(purse)
    least = purse.min(cost)
    if least.currency == market.to_currency
      qty_spent = least
    elsif least.currency == market.from_currency
      qty_spent = least/price
    end
    self.quantity -= least.amount
    least
  end

  def market_fee
    market.fee_percentage/100
  end

  def trade_profit(offer)
    raise "Incompatible offers. #{market.from_currency}=>#{market.to_currency} cannot trade with #{offer.market.from_currency}=>#{offer.market.to_currency} " unless market.to_currency == offer.market.from_currency
    offer.balance_with_fee(market.to_currency) - balance_with_fee
  end

  private
  def price_calc(currency)
    if currency == self.currency
      price
    else
      1/price
    end
  end

  def fee_factor(currency)
    if currency == market.from_currency
      (1+market_fee)
    elsif currency == market.to_currency
      (1-market_fee)
    end
  end

  def currency_check!(currency)
    if (currency != market.from_currency) && (currency != market.to_currency)
      raise "Invalid currency - #{currency} for market #{market.from_currency}/#{market.to_currency}"
    end
  end
end
