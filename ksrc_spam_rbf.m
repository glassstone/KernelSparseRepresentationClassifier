[num_data text_data] = xlsread('spam.xlsx');
sentences = tokenizedDocument(text_data(:,1));

bag = bagOfWords(sentences);

error_count =0;

Data = full(bag.Counts');
%matrix of all test samples
TestData = [Data(:,1:50) Data(:,5523:5572)];
TestLabels = [num_data(1:50,1); num_data(5523:5572,1)] ;
%matrix of all training samples
X = Data(:,51:5522);
labels = num_data(51:5522,1);
uniqlabels = unique(labels);
% finding number of unique classes
c = max(size(uniqlabels));




% m = dimensionality of training data
% n = total no of training samples
[m, n] = size(X);

testdata_n = size(TestData,2);
Predictions = zeros(testdata_n,1);


% noise threshold for data
epsilon = 0.001;

%define vector to save scores for each class
scores = zeros(testdata_n,c);



% used for calculating gamma for RBF kernel
mean_x = mean(X,2);
gamma = median (norm((X - mean_x),2).^(-2))

%calculating RBF gram matrix
n1sq = sum(X.^2,1);
n1 = size(X,2);
temp = (ones(n1,1)*n1sq)' + ones(n1,1)*n1sq -2*X'*X;
K = exp(temp.*-gamma);


%Finding Pseudo transformation matrix using KPCA
%Finding Eigen vectors and Eigen values
[V,D] = eig(K);
if ~issorted(diag(D), 'descend')
    [V,D] = eig(K);
    [D,I] = sort(diag(D),'descend');
    V = V(:, I);
end

%Normalizing eigen vectors
D1 = D.*sqrt(D);
D = D./D1;
V = V*diag(D);


%Select the first 10 eigen vectors for B
B = V(:,1:10);




for j = 1:testdata_n
    test = TestData(:,j);

    %calculating RBF test
    n2sq = sum(test.^2,1);
    n2 = size(test,2);
    temp = (ones(n2,1)*n1sq)' + ones(n1,1)*n2sq -2*X'*test;
    k = exp(temp.*-gamma);



    cvx_begin
      cvx_quiet(true);
      %coefficient vector to be found
      variable a(n,1);
      minimize norm(a,1);
      subject to
        norm(B'*k - B'*K*a, 2) <= epsilon   
    cvx_end




    %calculate residuals and scores
    for i=1:c
        delta_i = zeros(n,1);
        delta_i(find(labels==uniqlabels(i)),1) = a(find(labels==uniqlabels(i)),1);
        Residual_i = B'*k  - B'*K*delta_i;
        scores(j,i) = norm(Residual_i,2);
    end 
    [minval , index] = min(scores(j,:));
    Predictions(j,1) = uniqlabels (index);
    if (Predictions(j,1) ~= TestLabels(j,1))
        error_count = error_count +1;
        fprintf('Should be %f, but was %f.\n',TestLabels(j,1),Predictions(j,1));
    end
    
    
end




%{
%src with noise tolerance
%computations for coefficient vector using cvx
cvx_begin
  %cvx_quiet(true);
  %coefficient vector to be found
  variable a(n,1);
  minimize norm(a,1);
  subject to
    norm(test - X*a, 2) <= epsilon   
cvx_end

%{
for i=1:c
    R=test-a()*Traindata(find(Trainlabels==uniqlabels(i)),:);
    src_scores(:,i)=sqrt(sum(R.*R,2));
end
%}

Residual_1 =  test - X(:,n1)*a(n1,1)
score1 = sqrt(sum(Residual_1.*Residual_1,2))

Residual_2 =  test - X(:,n2)*a(n2,1)
score2 = sqrt(sum(Residual_2.*Residual_2,2))


%}

%[predictions,src_scores]=src(X,labels,Y,0.3)

